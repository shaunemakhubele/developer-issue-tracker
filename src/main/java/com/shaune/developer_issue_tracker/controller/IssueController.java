package com.shaune.developer_issue_tracker.controller;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import com.shaune.developer_issue_tracker.service.IssueService;
import jakarta.validation.Valid;
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
        Model model) {

    model.addAttribute(
            "issues",
            issueService.searchIssues(keyword, status, priority)
    );

    model.addAttribute("statuses", IssueStatus.values());
    model.addAttribute("priorities", IssuePriority.values());
    model.addAttribute("keyword", keyword == null ? "" : keyword);
    model.addAttribute("selectedStatus", status);
    model.addAttribute("selectedPriority", priority);

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
                "successMessage", "Issue created successfully!"
        );
        return "redirect:/";
    }

    @GetMapping("/issues/{id}/edit")
    public String editIssueForm(
            @PathVariable Long id,
            Model model) {

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
                "successMessage", "Issue updated successfully!"
        );
        return "redirect:/";
    }

    @PostMapping("/issues/{id}/delete")
    public String deleteIssue(
            @PathVariable Long id,
            RedirectAttributes redirectAttributes) {

        issueService.deleteIssue(id);
        redirectAttributes.addFlashAttribute(
                "successMessage", "Issue deleted successfully!"
        );
        return "redirect:/";
    }
}
