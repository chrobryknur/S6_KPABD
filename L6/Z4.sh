#!/bin/bash

# Wykonać zapytania:
# • pobranie listy wszystkich dokumentów, posortowanych
# • pobranie listy 2 „środkowych” dokumentów z posortowanej kolekcji (inaczej mówiąc: pobranie wybranej strony),
# • pobranie list dokumentów z nałożonym filtrem na atrybuty zagnieżdżonych dokumentów.

mongosh "mongodb+srv://cluster0.jypx7.mongodb.net/myFirstDatabase" --apiVersion 1 --username chrobryknur --password IW8doMzhZ0HSt9EY<<END
db.Wypozyczenie.find().sort({"Liczba_Dni":1});
db.Wypozyczenie.find().sort({"Liczba_Dni":1}).skip(1).limit(2);
db.Wypozyczenie.find({Egzemplarz: { Sygnatura: "S1" } });
END