package com.shaune.developer_issue_tracker;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class DeveloperIssueTrackerApplicationTests {

    @Autowired
    private MockMvc mockMvc;

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
}