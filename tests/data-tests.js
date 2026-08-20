"use strict";

const { faker } = require("@faker-js/faker");
const { setPerson, getPersons, getPerson } = require("../data/index");

const { getConnection } = require("../data/connection");
const expect = require("chai").expect;

describe("Data Tests", function () {
  this.timeout(15000);

  let connection;

  before(async function () {
    connection = await getConnection();
  });

  after(async function () {
    if (connection) {
      await connection.disconnect();
    }
  });

  it("Can connect to DB", async function () {
    expect(connection).to.be.an("object");
  });

  it("Can create Person in DB", async function () {
    const firstName = faker.name.firstName();
    const lastName = faker.name.lastName();

    await setPerson({
      firstName,
      lastName,
    });

    const persons = await getPersons();

    expect(persons).to.be.an("array");
    expect(persons.length).to.be.greaterThan(0);

    const createdPerson = persons.find(
      (person) =>
        person.firstName === firstName && person.lastName === lastName,
    );

    expect(createdPerson).to.exist;

    const person = await getPerson(createdPerson.id.toString());

    expect(person).to.be.an("object");
    expect(person.id).to.eq(createdPerson.id.toString());
    expect(person.firstName).to.eq(firstName);
    expect(person.lastName).to.eq(lastName);
  });
});
