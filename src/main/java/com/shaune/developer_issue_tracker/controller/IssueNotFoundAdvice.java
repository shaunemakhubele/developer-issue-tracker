package com.shaune.developer_issue_tracker.controller;

import org.springframework.http.HttpStatus;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;

@ControllerAdvice
public class IssueNotFoundAdvice {

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public String handleNotFound(IllegalArgumentException exception, Model model) {
        model.addAttribute(
            "message",
            "The issue could not be found. It may have been deleted or the URL may be incorrect."
        );
        return "error/404";
    }
}