
package com.shaune.developer_issue_tracker.service;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import com.shaune.developer_issue_tracker.repository.IssueRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class IssueService {

    private final IssueRepository issueRepository;

    public IssueService(IssueRepository issueRepository) {
        this.issueRepository = issueRepository;
    }

    public List<Issue> getAllIssues() {
        return issueRepository.findAll();
    }

    public List<Issue> searchIssues(
            String keyword,
            IssueStatus status,
            IssuePriority priority) {

        String cleanedKeyword =
                (keyword == null || keyword.isBlank()) ? "" : keyword.trim();

        return issueRepository.searchIssues(
                cleanedKeyword,
                status,
                priority
        );
    }

    public long getTotalIssueCount() {
        return issueRepository.count();
    }

    public long getIssueCountByStatus(IssueStatus status) {
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
        Issue issue = getIssueById(id);
        issueRepository.delete(issue);
    }
}
