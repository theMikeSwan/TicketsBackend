# TicketTracker Backend

Vapor based backend service for TicketTracker.

## General
This is the start of what will hopefully become the backend for a full featured ticket tracking package. The objective to to have this backend with a web based client along with iOS/macOS clients. The goal is not to copy every feature of something like Jira, rather to develop a ticket tracking system that can be used by groups of people working on projects that want a simple yet powerful ticket tracking solution.

Learning more about Vapor is also a major goal of this project.

At present you can do all the CRUD functions on tickets and users. Users currently only have a name and email address. Tickets have a number, summary, detail, type, status, date created, size, and assignee. They also track their status history so you can see when a ticket went from todo to in progress.

## Known Issues
Currently if you delete a user that still has tickets assigned those tickets will no longer be accessible. The only work around if you delete a user with tickets is to manually edit the db directly. This should be fixed soon.

## Running
TickerTracker is still in its infancy at the moment but you can run the backend and experiment with something like Postman or RESTed.

There is a Docker file, but it is the default one built by the Vapor toolbox and has not been tested as of yet. The easiest way to run the project is with Xcode currently. The project uses Postgres as its database so you will need a running instance. Below you will find how to get a Postgres container running for regular operation and testing.

###Start a db container for experimentation
If you want to experiment a bit with the project you will need to start Postgres in a container or directly on your machine. I would recommend a container as it makes it super easy to delete everything if desired.needed later.

The following bash command will start a container that will work when running the project from Xcode or Terminal:

```bash
docker run --name postgres -e POSTGRES_DB=vapor_database \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5432:5432 -d postgres
```

### Start a db container to run tests
The tests are setup to use a different Postgres instance running on a different port. This allows the database with your experimental data to be unaffected by the tests as all data is reset in the db for each test.

The following bash command will start a suitable test Postgres container on the proper port.

```bash
docker run --name postgres-test \
  -e POSTGRES_DB=vapor-test \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5433:5432 -d postgres
```

## Goals
The main goal is to develop a solid ticket tracking system that can be used by various groups working on projects.

- [x] Basic ticket CRUD
- [x] Track history of ticket status
- [x] Assign a user to a ticket
- [ ] Store the user that created the ticket
- [ ] Create sprints and add tickets to them
- [ ] Add tickets to other tickets (allow an epic to have stories, etc)
- [ ] Require users to authenticate before getting access
- [ ] Group tickets by project
- [ ] Add/edit comments to tickets

More features will likely appear over time as the service gets used.

## Contributing
As you can see from above there is still plenty to do to get this project to a 1.0 state. Feel free to contribute in anyway you are able. Documentation may not seem glamorous, but it is very useful. This project isn't following TDD, but tests should be written for any new code. Improvements to existing code are welcome as well.
