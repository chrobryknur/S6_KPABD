#!/bin/bash

# Uruchomić środowisko MongoDB korzystając z lokalnej instalacji lub usługi w chmurze. Podłączyć się klientem
# mongo i uruchomić polecenie pokazujące dostępne bazy danych.

mongosh "mongodb+srv://cluster0.jypx7.mongodb.net/myFirstDatabase" --apiVersion 1 --username chrobryknur --password IW8doMzhZ0HSt9EY<<END
show dbs
db
db.getCollectionNames()
db.users.insertOne({imie: "Marcin", nazwisko: "Dabrowski"})
db.getCollectionNames()
db.users.find()
db.users.drop()
db.getCollectionNames()
END