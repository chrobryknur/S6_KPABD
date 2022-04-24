#!/bin/bash

# Utworzyć odpowiednie reguły walidacji dla utworzonej struktury i sprawdzić, czy dodane dane je spełniają.
# Wprowadzenie do tematu: https://docs.mongodb.com/manual/core/schema-validation/

mongosh "mongodb+srv://cluster0.jypx7.mongodb.net/myFirstDatabase" --apiVersion 1 --username chrobryknur --password IW8doMzhZ0HSt9EY<<END
db.phoneBook.drop();

db.createCollection("phoneBook", {
   validator: {
      \$jsonSchema: {
         bsonType: "object",
         required: [ "phone", "name" ],
         properties: {
            phone: {
               bsonType: "string",
               description: "must be a string and is required"
            },
            name: {
               bsonType: "string",
               description: "must be a string and is required"
            }
         }
      }
   },
   validationLevel: "moderate"
});

db.phoneBook.insert({
   phone: "123-456-789",
   name: "Marcin"
});

db.phoneBook.insert({
   name: 1
})

db.phoneBook.validate();
END