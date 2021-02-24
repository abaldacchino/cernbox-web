@notToImplementOnOCIS
Feature: Resharing shared files with different permissions
  As a user
  I want to reshare received files and folders with other users with different permissions
  So that I can control the access on those files/folders by other collaborators

  Background:
    Given these users have been created with default attributes:
      | username |
      | Alice    |
      | Brian    |
      | Carol    |


  Scenario: Reshare a folder without share permissions using API and check if it is listed on the collaborators list for original owner
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share" permissions
    And user "Alice" has shared folder "simple-folder (2)" with user "Carol" with "read" permissions
    And user "Brian" has logged in using the webUI
    When the user opens the share dialog for folder "simple-folder" using the webUI
    Then user "Carol King" should be listed as "Advanced permissions" in the collaborators list for folder "simple-folder" on the webUI
    And no custom permissions should be set for collaborator "Carol King" for folder "simple-folder" on the webUI


  Scenario: Reshare a folder without share permissions using API and check if it is listed on the collaborators list for resharer
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share" permissions
    And user "Alice" has shared folder "simple-folder (2)" with user "Carol" with "read" permissions
    And user "Alice" has logged in using the webUI
    When the user opens the share dialog for folder "simple-folder (2)" using the webUI
    Then user "Carol King" should be listed as "Advanced permissions" in the collaborators list for folder "simple-folder (2)" on the webUI
    And no custom permissions should be set for collaborator "Carol King" for folder "simple-folder (2)" on the webUI


  Scenario: Reshare a folder without share permissions using API and check if the receiver can reshare
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share" permissions
    And user "Alice" has shared folder "simple-folder (2)" with user "Carol" with "read" permissions
    When user "Carol" logs in using the webUI
    Then the user should not be able to share folder "simple-folder (2)" using the webUI


  Scenario Outline: share a received folder with another user with same permissions(including share permissions) and check if the user is displayed in collaborators list for resharer
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "<permissions>" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "<role>" with permissions "<collaborators-permissions>" using the webUI
    Then user "Carol King" should be listed as "<displayed-role>" in the collaborators list for folder "simple-folder (2)" on the webUI
    And custom permissions "<displayed-permissions>" should be set for user "Carol King" for folder "simple-folder (2)" on the webUI
    And user "Carol" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Alice              |
      | share_with  | Carol              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | <permissions>      |
    Examples:
      | role                 | displayed-role       | collaborators-permissions     | displayed-permissions | permissions                         |
      | Viewer               | Viewer               | ,                             | ,                     | read, share                         |
      | Editor               | Editor               | ,                             | ,                     | all                                 |
      | Advanced permissions | Advanced permissions | share, create                 | share, create         | read, share, create                 |
      | Advanced permissions | Advanced permissions | update, share                 | share, update         | read, update, share                 |
      | Advanced permissions | Editor               | delete, share, create, update | ,                     | read, share, delete, update, create |


  Scenario Outline: share a received folder with another user with same permissions(including share permissions) and check if the user is displayed in collaborators list for original owner
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "<permissions>" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "<role>" with permissions "<collaborators-permissions>" using the webUI
    And the user re-logs in as "Brian" using the webUI
    Then user "Carol King" should be listed as "<displayed-role>" in the collaborators list for folder "simple-folder" on the webUI
    And custom permissions "<displayed-permissions>" should be set for user "Carol King" for folder "simple-folder" on the webUI
    And user "Alice Hansen" should be listed as "<displayed-role>" in the collaborators list for folder "simple-folder" on the webUI
    And custom permissions "<displayed-permissions>" should be set for user "Alice Hansen" for folder "simple-folder" on the webUI
    And user "Carol" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Alice              |
      | share_with  | Carol              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | <permissions>      |
    And user "Alice" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Brian              |
      | share_with  | Alice              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | <permissions>      |
    Examples:
      | role                 | displayed-role       | collaborators-permissions     | displayed-permissions | permissions                         |
      | Viewer               | Viewer               | ,                             | ,                     | read, share                         |
      | Editor               | Editor               | ,                             | ,                     | all                                 |
      | Advanced permissions | Advanced permissions | share, create                 | share, create         | read, share, create                 |
      | Advanced permissions | Advanced permissions | update, share                 | share, update         | read, update, share                 |
      | Advanced permissions | Editor               | delete, share, create, update | ,                     | read, share, delete, update, create |


  Scenario: share a folder with another user with share permissions and reshare without share permissions to different user, and check if user is displayed for original sharer
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Viewer" with permissions "," using the webUI
    And the user re-logs in as "Brian" using the webUI
    Then user "Carol King" should be listed as "Viewer" in the collaborators list for folder "simple-folder" on the webUI
    And no custom permissions should be set for collaborator "Carol King" for folder "simple-folder" on the webUI
    And user "Alice Hansen" should be listed as "Viewer" in the collaborators list for folder "simple-folder" on the webUI
    And user "Alice" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Brian              |
      | share_with  | Alice              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | read, share        |
    And user "Carol" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Alice              |
      | share_with  | Carol              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | read, share        |


  Scenario: share a folder with another user with share permissions and reshare without share permissions to different user, and check if user is displayed for the receiver
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Viewer" with permissions "," using the webUI
    And user "Carol" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Alice              |
      | share_with  | Carol              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | read, share        |


  Scenario Outline: share a file/folder without share permissions and check if another user can reshare
    Given user "Brian" has shared folder "<shared-entry-name>" with user "Alice" with "read" permissions
    When user "Alice" logs in using the webUI
    Then the user should not be able to share resource "<received-entry-name>" using the webUI
    Examples:
      | shared-entry-name | received-entry-name |
      | simple-folder     | simple-folder (2)   |
      | lorem.txt         | lorem (2).txt       |
      | simple-folder     | simple-folder (2)   |
      | lorem.txt         | lorem (2).txt       |


  Scenario Outline: share a received file/folder without share permissions and check if another user can reshare
    Given user "Brian" has shared folder "<shared-entry-name>" with user "Alice" with "all" permissions
    And user "Alice" has shared folder "<received-entry-name>" with user "Carol" with "read" permissions
    When user "Carol" logs in using the webUI
    Then the user should not be able to share resource "<received-entry-name>" using the webUI
    Examples:
      | shared-entry-name | received-entry-name |
      | simple-folder     | simple-folder (2)   |
      | lorem.txt         | lorem (2).txt       |


  Scenario: User is allowed to reshare a file/folder with the equivalent received permissions, and collaborators should not be listed for the receiver
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share, delete" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Advanced permissions" with permissions "share, delete" using the webUI
    And the user re-logs in as "Carol" using the webUI
    And the user opens the share dialog for folder "simple-folder (2)" using the webUI
    Then the current collaborators list should have order "Brian Murphy,Carol King"
    And user "Brian Murphy" should be listed as "Owner" reshared through "Alice Hansen" in the collaborators list on the webUI
    And user "Carol" should have received a share with these details:
      | field       | value               |
      | uid_owner   | Alice               |
      | share_with  | Carol               |
      | file_target | /simple-folder (2)  |
      | item_type   | folder              |
      | permissions | share, delete, read |


  Scenario: User is allowed to reshare a file/folder with the lesser permissions, and check if it is listed for original owner
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share, delete" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Advanced permissions" with permissions "delete" using the webUI
    And the user re-logs in as "Brian" using the webUI
    Then user "Alice Hansen" should be listed as "Advanced permissions" in the collaborators list for folder "simple-folder" on the webUI
    And custom permissions "share, delete" should be set for user "Alice Hansen" for folder "simple-folder" on the webUI
    And user "Carol King" should be listed as "Advanced permissions" in the collaborators list for folder "simple-folder" on the webUI
    And custom permissions "delete" should be set for user "Carol King" for folder "simple-folder" on the webUI
    And user "Carol" should have received a share with these details:
      | field       | value              |
      | uid_owner   | Alice              |
      | share_with  | Carol              |
      | file_target | /simple-folder (2) |
      | item_type   | folder             |
      | permissions | delete, read       |


  Scenario: User is not allowed to reshare a file/folder with the higher permissions
    Given user "Brian" has shared folder "simple-folder" with user "Alice" with "read, share, delete" permissions
    And user "Alice" has logged in using the webUI
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Advanced permissions" with permissions "share, delete, update" using the webUI
    Then the error message with header "Error while sharing." should be displayed on the webUI
    And as "Carol" folder "simple-folder (2)" should not exist


  Scenario: Reshare a file and folder from shared with me page
    Given user "Alice" has shared folder "simple-folder" with user "Brian"
    And user "Alice" has shared file "lorem.txt" with user "Brian"
    And user "Brian" has logged in using the webUI
    And the user has browsed to the shared-with-me page
    When the user shares folder "simple-folder (2)" with user "Carol King" as "Editor" using the webUI
    And the user shares file "lorem (2).txt" with user "Carol King" as "Editor" using the webUI
    Then as "Carol" folder "simple-folder (2)" should exist
    And as "Carol" file "lorem (2).txt" should exist


  Scenario: Reshare a file and folder from shared with others page
    Given user "Alice" has shared folder "simple-folder" with user "Brian"
    And user "Alice" has shared file "lorem.txt" with user "Brian"
    And user "Alice" has logged in using the webUI
    And the user has browsed to the shared-with-others page
    When the user shares folder "simple-folder" with user "Carol King" as "Editor" using the webUI
    And the user shares file "lorem.txt" with user "Carol King" as "Editor" using the webUI
    Then as "Carol" folder "simple-folder (2)" should exist
    And as "Carol" file "lorem (2).txt" should exist


  Scenario: Reshare a file and folder from favorites page
    Given user "Alice" has shared folder "simple-folder" with user "Brian"
    And user "Alice" has shared file "lorem.txt" with user "Brian"
    And user "Brian" has favorited element "simple-folder (2)"
    And user "Brian" has favorited element "lorem (2).txt"
    And user "Brian" has logged in using the webUI
    When the user browses to the favorites page using the webUI
    And the user shares folder "simple-folder (2)" with user "Carol King" as "Editor" using the webUI
    And the user shares file "lorem (2).txt" with user "Carol King" as "Editor" using the webUI
    Then as "Carol" folder "simple-folder (2)" should exist
    And as "Carol" file "lorem (2).txt" should exist


  Scenario: Resource owner sees resharer in collaborators list
    Given user "Carol" has been created with default attributes
    And user "Alice" has shared folder "simple-folder" with user "Brian"
    And user "Brian" has shared folder "simple-folder (2)" with user "Carol"
    When user "Alice" has logged in using the webUI
    And the user opens the share dialog for folder "simple-folder" using the webUI
    Then user "Brian Murphy" should be listed as "Editor" in the collaborators list on the webUI
    And user "Carol King" should be listed as "Editor" reshared through "Brian Murphy" in the collaborators list on the webUI


  Scenario: Share recipient sees resharer in collaborators list
    Given user "Carol" has been created with default attributes
    And user "David" has been created with default attributes
    And group "Davidgrp" has been created
    And user "David" has been added to group "Davidgrp"
    And user "Alice" has shared folder "simple-folder" with user "Brian"
    And user "Alice" has shared folder "simple-folder" with user "Carol"
    And user "Brian" has shared folder "simple-folder (2)" with user "David"
    And user "Carol" has shared folder "simple-folder (2)" with group "Davidgrp"
    When user "David" has logged in using the webUI
    And the user opens the share dialog for folder "simple-folder (2)" using the webUI
    Then user "Alice Hansen" should be listed as "Owner" reshared through "Carol King, Brian Murphy" in the collaborators list on the webUI
