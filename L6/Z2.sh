#!/bin/bash

# Dla bazy biblioteka zaproponować strukturę dokumentów i dodać dane zawierające 2 książki, 3 egzemplarze,
# 2 czytelników i 4 wypożyczenia. Upewnić się, że w zapronowanej strukturze występuje co najmniej jedno
# zagnieżdżenie dokumentów.

mongosh "mongodb+srv://cluster0.jypx7.mongodb.net/myFirstDatabase" --apiVersion 1 --username chrobryknur --password IW8doMzhZ0HSt9EY<<END

db.Ksiazka.drop();
db.Egzemplarz.drop();
db.Czytelnik.drop();
db.Wypozyczenie.drop();

const k1 = ObjectId();
const k2 = ObjectId();

const K1 = {
  _id: k1,
  ISBN: "1234567890",
  Tytul: "k1",
  Autor: "a1",
  Rok_Wydania: 2022,
  Cena: 10.00,
  Wypozyczona_Ostatni_Miesiac: false,
}

const K2 = {
  _id: k2,
  ISBN: "0987654321",
  Tytul: "k2",
  Autor: "a2",
  Rok_Wydania: 2021,
  Cena: 20.00,
  Wypozyczona_Ostatni_Miesiac: true,
}

db.Ksiazka.insert(K1);
db.Ksiazka.insert(K2);

const e1 = ObjectId();
const e2 = ObjectId();
const e3 = ObjectId();

const E1 = {
  _id: e1,
  Ksiazka: K1,
  Sygnatura: "S1"
};

const E2 = {
  _id: e2,
  Ksiazka: K1,
  Sygnatura: "S2"
};

const E3 = {
  _id: e3,
  Ksiazka: K2,
  Sygnatura: "S3"
};

db.Egzemplarz.insert(E1);
db.Egzemplarz.insert(E2);
db.Egzemplarz.insert(E3);

const c1 = ObjectId();
const c2 = ObjectId();

const C1 = {
  _id: c1,
  PESEL: "1234567890",
  Nazwisko: "Dabrowski",
  Miasto: "Wroclaw",
  Data_Urodzenia: "2000-01-01",
  Ostatnie_Wypozyczenie: "2021-01-01",
};

const C2 = {
  _id: c2,
  PESEL: "0987654321",
  Nazwisko: "Dabrowskii",
  Miasto: "Wrocław",
  Data_Urodzenia: "2000-02-02",
  Ostatenie_Wypozyczenie: "2021-05-05",
}

db.Czytelnik.insert(C1);
db.Czytelnik.insert(C2);

const w1 = ObjectId();
const w2 = ObjectId();
const w3 = ObjectId();
const w4 = ObjectId();

const W1 = {
  _id: w1,
  Egzemplarz: E1,
  Czytelnik: C1,
  Data: "2020-01-01",
  Liczba_Dni: 40,
};

const W2 = {
  _id: w2,
  Egzemplarz: E1,
  Czytelnik: C2,
  Data: "2021-01-01",
  Liczba_Dni: 30
};

const W3 = {
  _id: w3,
  Egzemplarz: E2,
  Czytelnik: C2,
  Data: "2020-01-01",
  Liczba_Dni: 20
};

const W4 = {
  _id: w4,
  Egzemplarz: E3,
  Czytelnik: C2,
  Data: "2020-01-01",
  Liczba_Dni: 10
};

db.Wypozyczenie.insert(W1);
db.Wypozyczenie.insert(W2);
db.Wypozyczenie.insert(W3);
db.Wypozyczenie.insert(W4);

db.Ksiazka.find()
db.Egzemplarz.find()
db.Czytelnik.find()
db.Wypozyczenie.find()

END