
package com.shaune.developer_issue_tracker.repository;

import com.shaune.developer_issue_tracker.model.Issue;
import com.shaune.developer_issue_tracker.model.IssuePriority;
import com.shaune.developer_issue_tracker.model.IssueStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IssueRepository extends JpaRepository<Issue, Long> {

    @Query("""
        SELECT i FROM Issue i
        WHERE (:keyword IS NULL OR :keyword = ''
               OR LOWER(i.title) LIKE LOWER(CONCAT('%', :keyword, '%'))
               OR LOWER(i.description) LIKE LOWER(CONCAT('%', :keyword, '%'))
               OR LOWER(i.assignee) LIKE LOWER(CONCAT('%', :keyword, '%')))
        AND (:status IS NULL OR i.status = :status)
        AND (:priority IS NULL OR i.priority = :priority)
        ORDER BY i.createdAt DESC
        """)
    List<Issue> searchIssues(
            @Param("keyword") String keyword,
            @Param("status") IssueStatus status,
            @Param("priority") IssuePriority priority
    );
}
