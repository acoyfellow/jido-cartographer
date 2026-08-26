@live @cmux
Feature: Deployed jido-cartographer
  The public deployment maps a bounded GitHub source snapshot with Jido agents
  and presents deterministic results without an LLM.

  Background:
    Given I open "https://jido-cartographer.coy.workers.dev" in a cmux browser surface
    And the document has finished loading

  Scenario: The deployment presents its identity over HTTPS
    Then the current URL is "https://jido-cartographer.coy.workers.dev/"
    And the document title is "jido-cartographer"
    And the page says "JIDO 2.X × BEAM CONCURRENCY"
    And the page says "no LLM required"

  Scenario: The index form has useful defaults
    Then the public repository field contains "https://github.com/agentjido/jido"
    And the Git ref field contains "HEAD"
    And the "Index repo" button is enabled

  Scenario: The layout remains usable on a mobile viewport
    When I set the logical viewport to 390 by 844 pixels
    Then the public repository field is visible
    And the Git ref field is visible
    And the "Index repo" button is visible
    And the document has no horizontal overflow

  Scenario: A non-GitHub host fails closed in the browser
    When I enter "https://example.com/acme/project" as the public repository
    And I submit the index form
    Then the status says "only credential-free https://github.com repository URLs are allowed"
    And no results are displayed

  @shared-index
  Scenario: A valid public repository starts an asynchronous index
    When I submit "https://github.com/agentjido/jido" at ref "v2.3.3"
    Then the first API response has status 202
    And the response contains a job ID
    And the browser reports that agents are running before completion

  @shared-index
  Scenario: The asynchronous index reaches a terminal success state
    Given the shared live index job has been submitted
    When I poll its result for at most 90 seconds
    Then its terminal status is "complete"
    And its repository is "agentjido/jido" at ref "v2.3.3"

  @shared-index
  Scenario: The deployed aggregate matches the pinned repository facts
    Given the shared live index job is complete
    Then the summary contains 297 files
    And the summary contains 78420 lines
    And the summary contains 2840 symbols
    And the summary contains 1104 dependency edges
    And the run reports 297 agents spawned

  @shared-index
  Scenario: The UI renders measured timing instead of a claim
    Given the shared live index job is complete
    Then the UI shows a numeric agent analysis duration in milliseconds
    And the UI shows a numeric total duration in milliseconds
    And the total duration is not less than the agent analysis duration

  @shared-index
  Scenario: The UI renders the deterministic language breakdown
    Given the shared live index job is complete
    Then the language panel shows "Elixir" with 296 files
    And the language panel shows "Shell" with 1 file

  @shared-index
  Scenario: The UI renders dependency and source-file details
    Given the shared live index job is complete
    Then at least one dependency edge is visible
    And the source table contains 297 rows
    And every source row has a path, language, line count, byte count, and symbol cell
