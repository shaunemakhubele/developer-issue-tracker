
$ErrorActionPreference = "Stop"
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Write-ProjectFile($relativePath, $content) {
    $fullPath = Join-Path (Get-Location) $relativePath
    $directory = Split-Path $fullPath -Parent

    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($fullPath, $content, $utf8)
    Write-Host "Updated $relativePath" -ForegroundColor Green
}

# 1. Repository: combined search, filtering, sorting and pagination.
Write-ProjectFile "src/main/java/com/shaune/developer_issue_tracker/repository/IssueRepository.java" @'
package com.shaune.developer_issue_tracker.repository;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface IssueRepository extends JpaRepository<Issue, Long> {

    @Query(
        value = """
            SELECT i FROM Issue i
            WHERE (
                :keyword = ''
                OR LOWER(i.title) LIKE LOWER(CONCAT('%', :keyword, '%'))
                OR LOWER(i.description) LIKE LOWER(CONCAT('%', :keyword, '%'))
                OR LOWER(COALESCE(i.assignee, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
            )
            AND (:status IS NULL OR i.status = :status)
            AND (:priority IS NULL OR i.priority = :priority)
            """,
        countQuery = """
            SELECT COUNT(i) FROM Issue i
            WHERE (
                :keyword = ''
                OR LOWER(i.title) LIKE LOWER(CONCAT('%', :keyword, '%'))
                OR LOWER(i.description) LIKE LOWER(CONCAT('%', :keyword, '%'))
                OR LOWER(COALESCE(i.assignee, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
            )
            AND (:status IS NULL OR i.status = :status)
            AND (:priority IS NULL OR i.priority = :priority)
            """
    )
    Page<Issue> searchIssues(
            @Param("keyword") String keyword,
            @Param("status") IssueStatus status,
            @Param("priority") IssuePriority priority,
            Pageable pageable
    );

    long countByStatus(IssueStatus status);
}
'@

# 2. Service: preserve CRUD and expose filtered, paginated results.
Write-ProjectFile "src/main/java/com/shaune/developer_issue_tracker/service/IssueService.java" @'
package com.shaune.developer_issue_tracker.service;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import com.shaune.developer_issue_tracker.repository.IssueRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class IssueService {

    private final IssueRepository issueRepository;

    public IssueService(IssueRepository issueRepository) {
        this.issueRepository = issueRepository;
    }

    public Page<Issue> searchIssues(
            String keyword,
            IssueStatus status,
            IssuePriority priority,
            Pageable pageable) {

        String cleanedKeyword =
                keyword == null ? "" : keyword.trim();

        return issueRepository.searchIssues(
                cleanedKeyword,
                status,
                priority,
                pageable
        );
    }

    public long getTotalIssues() {
        return issueRepository.count();
    }

    public long countByStatus(IssueStatus status) {
        return issueRepository.countByStatus(status);
    }

    public Issue getIssueById(Long id) {
        return issueRepository.findById(id)
                .orElseThrow(() ->
                        new IllegalArgumentException("Issue not found: " + id));
    }

    public Issue createIssue(Issue issue) {
        return issueRepository.save(issue);
    }

    public Issue updateIssue(Long id, Issue updatedIssue) {
        Issue existingIssue = getIssueById(id);

        existingIssue.setTitle(updatedIssue.getTitle());
        existingIssue.setDescription(updatedIssue.getDescription());
        existingIssue.setStatus(updatedIssue.getStatus());
        existingIssue.setPriority(updatedIssue.getPriority());
        existingIssue.setAssignee(updatedIssue.getAssignee());

        return issueRepository.save(existingIssue);
    }

    public void deleteIssue(Long id) {
        issueRepository.deleteById(id);
    }
}
'@

# 3. Controller: dashboard statistics, validated sorting, filters and pagination.
Write-ProjectFile "src/main/java/com/shaune/developer_issue_tracker/controller/IssueController.java" @'
package com.shaune.developer_issue_tracker.controller;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import com.shaune.developer_issue_tracker.service.IssueService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class IssueController {

    private final IssueService issueService;

    public IssueController(IssueService issueService) {
        this.issueService = issueService;
    }

    @GetMapping("/")
    public String dashboard(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) IssueStatus status,
            @RequestParam(required = false) IssuePriority priority,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String direction,
            Model model) {

        String safeSortBy = switch (sortBy) {
            case "title", "status", "priority", "createdAt" -> sortBy;
            default -> "createdAt";
        };

        Sort.Direction safeDirection =
                "asc".equalsIgnoreCase(direction)
                        ? Sort.Direction.ASC
                        : Sort.Direction.DESC;

        int safePage = Math.max(page, 0);

        Pageable pageable = PageRequest.of(
                safePage,
                10,
                Sort.by(safeDirection, safeSortBy)
        );

        Page<Issue> issuePage = issueService.searchIssues(
                keyword, status, priority, pageable
        );

        // If a deletion or filter change leaves the page out of range,
        // show the last valid page instead of an empty out-of-range page.
        if (issuePage.getTotalPages() > 0
                && safePage >= issuePage.getTotalPages()) {
            safePage = issuePage.getTotalPages() - 1;
            pageable = PageRequest.of(safePage, 10,
                    Sort.by(safeDirection, safeSortBy));
            issuePage = issueService.searchIssues(
                    keyword, status, priority, pageable);
        }

        model.addAttribute("issues", issuePage.getContent());
        model.addAttribute("issuePage", issuePage);
        model.addAttribute("statuses", IssueStatus.values());
        model.addAttribute("priorities", IssuePriority.values());
        model.addAttribute("keyword", keyword == null ? "" : keyword);
        model.addAttribute("selectedStatus", status);
        model.addAttribute("selectedPriority", priority);
        model.addAttribute("sortBy", safeSortBy);
        model.addAttribute("direction", safeDirection.name().toLowerCase());

        model.addAttribute("totalIssues", issueService.getTotalIssues());
        model.addAttribute("openIssues",
                issueService.countByStatus(IssueStatus.OPEN));
        model.addAttribute("inProgressIssues",
                issueService.countByStatus(IssueStatus.IN_PROGRESS));
        model.addAttribute("resolvedIssues",
                issueService.countByStatus(IssueStatus.RESOLVED));

        return "issues/list";
    }

    @GetMapping("/issues/new")
    public String newIssueForm(Model model) {
        model.addAttribute("issue", new Issue());
        model.addAttribute("statuses", IssueStatus.values());
        model.addAttribute("priorities", IssuePriority.values());
        return "issues/form";
    }

    @PostMapping("/issues")
    public String createIssue(
            @Valid @ModelAttribute("issue") Issue issue,
            BindingResult bindingResult,
            Model model,
            RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            model.addAttribute("statuses", IssueStatus.values());
            model.addAttribute("priorities", IssuePriority.values());
            return "issues/form";
        }

        issueService.createIssue(issue);
        redirectAttributes.addFlashAttribute(
                "successMessage", "Issue created successfully!");
        return "redirect:/";
    }

    @GetMapping("/issues/{id}/edit")
    public String editIssueForm(@PathVariable Long id, Model model) {
        model.addAttribute("issue", issueService.getIssueById(id));
        model.addAttribute("statuses", IssueStatus.values());
        model.addAttribute("priorities", IssuePriority.values());
        return "issues/form";
    }

    @PostMapping("/issues/{id}")
    public String updateIssue(
            @PathVariable Long id,
            @Valid @ModelAttribute("issue") Issue issue,
            BindingResult bindingResult,
            Model model,
            RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            issue.setIdForForm(id);
            model.addAttribute("statuses", IssueStatus.values());
            model.addAttribute("priorities", IssuePriority.values());
            return "issues/form";
        }

        issueService.updateIssue(id, issue);
        redirectAttributes.addFlashAttribute(
                "successMessage", "Issue updated successfully!");
        return "redirect:/";
    }

    @PostMapping("/issues/{id}/delete")
    public String deleteIssue(
            @PathVariable Long id,
            RedirectAttributes redirectAttributes) {

        issueService.deleteIssue(id);
        redirectAttributes.addFlashAttribute(
                "successMessage", "Issue deleted successfully!");
        return "redirect:/";
    }
}
'@

# 4. Dashboard: statistics, search, filters, sorting, pagination and responsive styling.
Write-ProjectFile "src/main/resources/templates/issues/list.html" @'
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Issue Tracker | Dashboard</title>
    <style>
        * { box-sizing: border-box; }
        body { margin:0; font-family:Arial,sans-serif; background:#f4f6fa; color:#202938; }
        header { background:#172033; color:white; padding:22px 6%; display:flex; justify-content:space-between; align-items:center; gap:16px; }
        header h1 { margin:0; font-size:22px; }
        main { max-width:1200px; margin:32px auto; padding:0 20px; }
        .top { display:flex; justify-content:space-between; align-items:center; gap:15px; flex-wrap:wrap; margin-bottom:24px; }
        h2 { margin:0 0 8px; }
        .muted { color:#667085; }
        .button { display:inline-block; padding:11px 15px; border-radius:7px; text-decoration:none; border:0; cursor:pointer; font-weight:bold; font-size:14px; }
        .primary { background:#4f46e5; color:white; }
        .secondary { background:#e8eaf0; color:#202938; }
        .danger { background:#fee2e2; color:#991b1b; }
        .notice { background:#dcfce7; color:#166534; padding:13px; border-radius:7px; margin-bottom:20px; }
        .stats { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:16px; margin-bottom:24px; }
        .stat { background:white; border:1px solid #e5e7eb; border-radius:12px; padding:20px; }
        .stat-label { color:#667085; font-size:13px; font-weight:bold; }
        .stat-number { font-size:30px; font-weight:bold; margin-top:8px; }
        .panel { background:white; border:1px solid #e5e7eb; border-radius:12px; overflow:hidden; }
        .panel-heading { padding:20px; border-bottom:1px solid #e5e7eb; }
        .filters { display:grid; grid-template-columns:minmax(190px,2fr) repeat(3,minmax(130px,1fr)); gap:10px; margin-top:16px; }
        input, select { width:100%; padding:11px; border:1px solid #d1d5db; border-radius:7px; background:white; color:#202938; }
        .filter-actions { display:flex; gap:8px; flex-wrap:wrap; margin-top:12px; }
        .table-wrap { overflow-x:auto; }
        table { width:100%; border-collapse:collapse; }
        th,td { padding:15px 18px; text-align:left; border-bottom:1px solid #edf0f4; vertical-align:middle; }
        th { font-size:12px; text-transform:uppercase; color:#667085; background:#fafbfc; }
        th a { color:inherit; text-decoration:none; }
        .issue-title { font-weight:bold; }
        .description { color:#667085; font-size:13px; margin-top:5px; max-width:320px; overflow-wrap:anywhere; }
        .tag { display:inline-block; padding:5px 9px; border-radius:20px; font-size:12px; font-weight:bold; white-space:nowrap; }
        .OPEN { background:#dbeafe; color:#1d4ed8; }
        .IN_PROGRESS { background:#fef3c7; color:#92400e; }
        .RESOLVED { background:#dcfce7; color:#166534; }
        .LOW { background:#e5e7eb; color:#374151; }
        .MEDIUM { background:#dbeafe; color:#1d4ed8; }
        .HIGH { background:#ffedd5; color:#9a3412; }
        .CRITICAL { background:#fee2e2; color:#991b1b; }
        .actions { display:flex; gap:8px; align-items:center; }
        .actions form { margin:0; }
        .empty { padding:45px 20px; text-align:center; color:#667085; }
        .pagination { display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; padding:18px 20px; }
        .page-links { display:flex; gap:8px; align-items:center; flex-wrap:wrap; }
        .page-number { padding:9px 12px; border-radius:6px; background:#e8eaf0; color:#202938; text-decoration:none; }
        .page-number.current { background:#4f46e5; color:white; }
        footer { text-align:center; padding:25px; color:#667085; font-size:13px; }
        @media(max-width:850px) { .stats { grid-template-columns:repeat(2,minmax(0,1fr)); } .filters { grid-template-columns:repeat(2,minmax(0,1fr)); } }
        @media(max-width:550px) { header { padding:18px 20px; } main { margin-top:22px; } .stats { gap:10px; } .stat { padding:14px; } .stat-number { font-size:25px; } .filters { grid-template-columns:1fr; } th,td { padding:12px; } }
    </style>
</head>
<body>
<header>
    <h1>Issue Tracker</h1>
    <span>Developer Workspace</span>
</header>

<main>
    <div class="top">
        <div>
            <h2>Issues Dashboard</h2>
            <div class="muted">Track bugs, tasks, and development work.</div>
        </div>
        <a class="button primary" th:href="@{/issues/new}">+ Create Issue</a>
    </div>

    <div class="notice" th:if="${successMessage}"
         th:text="${successMessage}" role="status"></div>

    <section class="stats">
        <div class="stat">
            <div class="stat-label">TOTAL ISSUES</div>
            <div class="stat-number" th:text="${totalIssues}">0</div>
        </div>
        <div class="stat">
            <div class="stat-label">OPEN</div>
            <div class="stat-number" th:text="${openIssues}">0</div>
        </div>
        <div class="stat">
            <div class="stat-label">IN PROGRESS</div>
            <div class="stat-number" th:text="${inProgressIssues}">0</div>
        </div>
        <div class="stat">
            <div class="stat-label">RESOLVED</div>
            <div class="stat-number" th:text="${resolvedIssues}">0</div>
        </div>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <strong>Issues</strong>
            <form th:action="@{/}" method="get">
                <div class="filters">
                    <input type="search" name="keyword"
                           placeholder="Search title, description, assignee..."
                           th:value="${keyword}">

                    <select name="status">
                        <option value="">All statuses</option>
                        <option th:each="item : ${statuses}"
                                th:value="${item}"
                                th:text="${#strings.replace(item.name(), '_', ' ')}"
                                th:selected="${item == selectedStatus}"></option>
                    </select>

                    <select name="priority">
                        <option value="">All priorities</option>
                        <option th:each="item : ${priorities}"
                                th:value="${item}"
                                th:text="${item}"
                                th:selected="${item == selectedPriority}"></option>
                    </select>

                    <select name="sortBy">
                        <option value="createdAt" th:selected="${sortBy == 'createdAt'}">Date created</option>
                        <option value="title" th:selected="${sortBy == 'title'}">Title</option>
                        <option value="priority" th:selected="${sortBy == 'priority'}">Priority</option>
                        <option value="status" th:selected="${sortBy == 'status'}">Status</option>
                    </select>
                </div>

                <input type="hidden" name="direction"
                       th:value="${direction}">

                <div class="filter-actions">
                    <button class="button primary" type="submit">Apply filters</button>
                    <a class="button secondary" th:href="@{/}">Clear filters</a>
                    <button class="button secondary" type="submit" name="direction"
                            th:value="${direction == 'asc' ? 'desc' : 'asc'}"
                            th:text="${direction == 'asc' ? 'Sort descending' : 'Sort ascending'}">
                        Change sort direction
                    </button>
                </div>
            </form>
        </div>

        <div class="table-wrap" th:if="${!#lists.isEmpty(issues)}">
            <table>
                <thead>
                <tr>
                    <th>Issue</th>
                    <th>Priority</th>
                    <th>Status</th>
                    <th>Assignee</th>
                    <th>Actions</th>
                </tr>
                </thead>
                <tbody>
                <tr th:each="issue : ${issues}">
                    <td>
                        <div class="issue-title" th:text="${issue.title}">Sample issue</div>
                        <div class="description" th:text="${issue.description}">Issue description</div>
                    </td>
                    <td>
                        <span class="tag"
                              th:classappend="${' ' + issue.priority.name()}"
                              th:text="${issue.priority}">MEDIUM</span>
                    </td>
                    <td>
                        <span class="tag"
                              th:classappend="${' ' + issue.status.name()}"
                              th:text="${#strings.replace(issue.status.name(), '_', ' ')}">OPEN</span>
                    </td>
                    <td th:text="${issue.assignee != null and !#strings.isEmpty(issue.assignee) ? issue.assignee : 'Unassigned'}">Unassigned</td>
                    <td>
                        <div class="actions">
                            <a class="button secondary"
                               th:href="@{/issues/{id}/edit(id=${issue.id})}">Edit</a>
                            <form th:action="@{/issues/{id}/delete(id=${issue.id})}"
                                  method="post"
                                  onsubmit="return confirm('Delete this issue?');">
                                <button class="button danger" type="submit">Delete</button>
                            </form>
                        </div>
                    </td>
                </tr>
                </tbody>
            </table>
        </div>

        <div class="empty" th:if="${#lists.isEmpty(issues)}">
            <h3>No matching issues</h3>
            <p>Try changing your search or filters, or create a new issue.</p>
            <a class="button primary" th:href="@{/issues/new}">Create Issue</a>
        </div>

        <div class="pagination" th:if="${issuePage.totalPages > 0}">
            <span class="muted"
                  th:text="'Page ' + (issuePage.number + 1) + ' of ' + issuePage.totalPages + ' · ' + issuePage.totalElements + ' matching issues'">
                Page 1 of 1
            </span>

            <div class="page-links">
                <a class="page-number"
                   th:if="${issuePage.hasPrevious()}"
                   th:href="@{/(page=${issuePage.number - 1}, keyword=${keyword}, status=${selectedStatus}, priority=${selectedPriority}, sortBy=${sortBy}, direction=${direction})}">Previous</a>

                <a class="page-number"
                   th:each="pageNumber : ${#numbers.sequence(0, issuePage.totalPages - 1)}"
                   th:if="${pageNumber >= issuePage.number - 2 and pageNumber <= issuePage.number + 2}"
                   th:classappend="${pageNumber == issuePage.number ? ' current' : ''}"
                   th:href="@{/(page=${pageNumber}, keyword=${keyword}, status=${selectedStatus}, priority=${selectedPriority}, sortBy=${sortBy}, direction=${direction})}"
                   th:text="${pageNumber + 1}">1</a>

                <a class="page-number"
                   th:if="${issuePage.hasNext()}"
                   th:href="@{/(page=${issuePage.number + 1}, keyword=${keyword}, status=${selectedStatus}, priority=${selectedPriority}, sortBy=${sortBy}, direction=${direction})}">Next</a>
            </div>
        </div>
    </section>
</main>

<footer>Developer Issue Tracker · Java · Spring Boot · PostgreSQL</footer>
</body>
</html>
'@

Write-Host ""
Write-Host "Dashboard files updated." -ForegroundColor Cyan
Write-Host "Next: run the build command to check compilation."
