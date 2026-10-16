package com.shaune.developer_issue_tracker;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import com.shaune.developer_issue_tracker.repository.IssueRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class DeveloperIssueTrackerApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private IssueRepository issueRepository;

    @Test
    void contextLoads() {
    }

    @Test
    void dashboardLoadsSuccessfully() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(view().name("issues/list"))
                .andExpect(model().attributeExists("issues"))
                .andExpect(model().attributeExists("statuses"))
                .andExpect(model().attributeExists("priorities"));
    }

    @Test
    void newIssueFormLoadsSuccessfully() throws Exception {
        mockMvc.perform(get("/issues/new"))
                .andExpect(status().isOk())
                .andExpect(view().name("issues/form"))
                .andExpect(model().attributeExists("issue"))
                .andExpect(model().attributeExists("statuses"))
                .andExpect(model().attributeExists("priorities"));
    }

    @Test
    void blankTitleAndDescriptionAreRejected() throws Exception {
        mockMvc.perform(post("/issues")
                        .param("title", "")
                        .param("description", "")
                        .param("status", "OPEN")
                        .param("priority", "MEDIUM")
                        .param("assignee", ""))
                .andExpect(status().isOk())
                .andExpect(view().name("issues/form"))
                .andExpect(model().attributeHasFieldErrors(
                        "issue", "title", "description"));
    }

    @Test
    void missingIssueShowsNotFoundPage() throws Exception {
        mockMvc.perform(get("/issues/999999999/edit"))
                .andExpect(status().isNotFound())
                .andExpect(view().name("error/404"))
                .andExpect(model().attributeExists("message"));
    }

    @Test
    void issueCanBeCreated() throws Exception {
        String title = "Automated test - create issue";

        mockMvc.perform(post("/issues")
                        .param("title", title)
                        .param("description", "Testing issue creation")
                        .param("status", "OPEN")
                        .param("priority", "HIGH")
                        .param("assignee", "Test Developer"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));

        Issue savedIssue = issueRepository.findAll().stream()
                .filter(issue -> title.equals(issue.getTitle()))
                .findFirst()
                .orElseThrow(() ->
                        new AssertionError("Created issue was not found"));

        assertEquals("Testing issue creation", savedIssue.getDescription());
        assertEquals(IssueStatus.OPEN, savedIssue.getStatus());
        assertEquals(IssuePriority.HIGH, savedIssue.getPriority());
        assertEquals("Test Developer", savedIssue.getAssignee());
        assertNotNull(savedIssue.getId());
    }

    @Test
    void issueCanBeUpdated() throws Exception {
        Issue issue = new Issue();
        issue.setTitle("Original test issue");
        issue.setDescription("Original description");
        issue.setStatus(IssueStatus.OPEN);
        issue.setPriority(IssuePriority.LOW);
        issue.setAssignee("Original Developer");

        Issue savedIssue = issueRepository.saveAndFlush(issue);

        mockMvc.perform(post("/issues/{id}", savedIssue.getId())
                        .param("title", "Updated test issue")
                        .param("description", "Updated description")
                        .param("status", "IN_PROGRESS")
                        .param("priority", "CRITICAL")
                        .param("assignee", "New Developer"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));

        Issue updatedIssue = issueRepository.findById(savedIssue.getId())
                .orElseThrow(() ->
                        new AssertionError("Updated issue was not found"));

        assertEquals("Updated test issue", updatedIssue.getTitle());
        assertEquals("Updated description", updatedIssue.getDescription());
        assertEquals(IssueStatus.IN_PROGRESS, updatedIssue.getStatus());
        assertEquals(IssuePriority.CRITICAL, updatedIssue.getPriority());
        assertEquals("New Developer", updatedIssue.getAssignee());
    }

    @Test
    void issueCanBeDeleted() throws Exception {
        Issue issue = new Issue();
        issue.setTitle("Issue to delete");
        issue.setDescription("Testing issue deletion");
        issue.setStatus(IssueStatus.OPEN);
        issue.setPriority(IssuePriority.MEDIUM);

        Issue savedIssue = issueRepository.saveAndFlush(issue);
        Long issueId = savedIssue.getId();

        mockMvc.perform(post("/issues/{id}/delete", issueId))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));

        assertFalse(issueRepository.existsById(issueId),
                "Issue should no longer exist after deletion");
    }
}