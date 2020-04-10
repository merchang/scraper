### SCRAPER!

A no frills utility for pulling all data from an endpoint in the Canvas API. Returns data as a JSON file.

#### Usage
`ruby scrape.rb -u https://url.edu/api/v1/your/endpoint`

#### Utility Commands
`-q --quiz` Returns a timeline of quiz version changes according to submission data.


`ruby scrape.rb -q url.edu/api/v1/courses/123/quizzes/456` =>
```
 22 total submissions to quiz
 2 different quiz versions taken by students
 2020-01-10T00:00:00Z : assignment object created
 2020-01-16T23:00:00Z : assignment object last updated
 ============
 2020-01-11T16:00:00Z : version 5 first taken
 2020-01-11T17:00:00Z : version 5 last taken
 2020-01-15T23:00:00Z : version 11 first taken
 2020-01-15T16:00:00Z : version 11 last taken
 ```