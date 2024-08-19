/*
-- ===========================================================================
-- IFT723_cre_table.sql
-- ---------------------------------------------------------------------------
Activité : IFT187_2023-1
Encodage : UTF-8, sans BOM; fin de ligne Unix (LF)
Plateforme : PostgreSQL 16
Responsable : Mohamed.Boubacar.Boureima@usherbrooke.ca 
              Othman.El.Biyaali@USherbrooke.ca 
              Alseny.Toumany.Soumah@usherbrooke.ca
              Maxime.Sourceaux@usherbrooke.ca 
Version : 1.0
Statut : en vigueur
Résumé : Création des tables de la base de données.
-- ===========================================================================
*/


DROP SCHEMA IF EXISTS "IFT723" CASCADE;


--------Définition du schéma--------
CREATE SCHEMA IF NOT EXISTS "IFT723";
SET SCHEMA 'IFT723';


--------Ajout des extensions à la BD--------
CREATE EXTENSION IF NOT EXISTS "btree_gist";


--------Définition des domaines--------
CREATE DOMAIN Estampille AS TIMESTAMP(0);--Tronqué à la seconde
CREATE TYPE TSRANGE_sec AS RANGE (subtype = Estampille);

--Pour la table adresse--
CREATE DOMAIN Adresse_Rue AS TEXT
  CHECK (LENGTH(VALUE) <= 250); 

CREATE DOMAIN Adresse_Appartement AS INTEGER
  CHECK (VALUE >= 0);

CREATE DOMAIN Adresse_Ville AS TEXT
  CHECK (LENGTH(VALUE) <= 20);

CREATE DOMAIN Adresse_Region AS TEXT
  CHECK (LENGTH(VALUE) <= 100);

CREATE DOMAIN Adresse_CP AS TEXT
  CHECK (VALUE ~ '^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$');

CREATE DOMAIN Adresse_Pays AS TEXT
  CHECK (LENGTH(VALUE) <= 30);

--Pour la table étudiant--
CREATE DOMAIN nom_prenom AS TEXT
  CHECK (LENGTH(VALUE) <= 50); 

CREATE DOMAIN Etudiant_Matricule AS CHAR(10)
  CHECK (LENGTH(VALUE) = 10);

--Selon la norme HTML5
--https://dba.stackexchange.com/questions/68266/what-is-the-best-way-to-store-an-email-address-in-postgresql
CREATE DOMAIN email AS TEXT
  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );

--Valide pour Canada et US
CREATE DOMAIN phoneNumber AS VARCHAR(10) 
	CHECK(VALUE ~ '^[0-9]{10}$');

--------Création des tables--------
--------Adresse courante--------
-- L'adresse est identifié par "code" qui possède un numéro d'appart, la rue, la ville, le region, le code postal, et le pays.
CREATE TABLE Adresse_Courante (
    adresseID INT NOT NULL,
	adresseID_since Estampille NOT NULL,

    appartement Adresse_Appartement,
    rue Adresse_Rue NOT NULL,
    ville Adresse_Ville NOT NULL,
    region Adresse_Region NOT NULL,
    code_postal Adresse_CP NOT NULL,
    pays Adresse_Pays NOT NULL,
	Localisation_since Estampille NOT NULL,
	
    CONSTRAINT Adresse_PK PRIMARY KEY (adresseID)
);


--------Adresse courante log--------
CREATE TABLE IF NOT EXISTS Adresse_Courante_Log(
    adresseID INT NOT NULL,
	adresseID_since Estampille NOT NULL,

    appartement Adresse_Appartement,
    rue Adresse_Rue NOT NULL,
    ville Adresse_Ville NOT NULL,
    region Adresse_Region NOT NULL,
    code_postal Adresse_CP NOT NULL,
    pays Adresse_Pays NOT NULL,
	Localisation_since Estampille NOT NULL,

	adresse_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Adresse_Courante_Log_INDEX
	ON Adresse_Courante_Log USING GIST(adresseID, adresse_transaction);


--------Adresse code validité--------
CREATE TABLE IF NOT EXISTS Adresse_adresseID_Validite(
	adresseID INT NOT NULL,
	adresseID_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Adresse_AdresseID_Validite_INDEX
	ON Adresse_adresseID_Validite USING GIST(adresseID, adresseID_validite);

--Vérification
ALTER TABLE Adresse_adresseID_Validite
--Redondance
	ADD CONSTRAINT Adresse_adresseID_Validite_Redondance
		EXCLUDE USING GIST (adresseID WITH =, 
							adresseID_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Adresse_adresseID_Validite
	ADD CONSTRAINT Adresse_adresseID_Validite_Circonlocution
		EXCLUDE USING GIST (adresseID WITH =, 
							adresseID_validite WITH -|-);

--Contradiction
--Sans objet, pas d'attribut non clé


--------Adresse code log--------
CREATE TABLE IF NOT EXISTS Adresse_adresseID_Log(
	adresseID INT NOT NULL,
	adresseID_validite TSRANGE_sec NOT NULL,
	adresseID_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Adresse_adresseID_Log_INDEX
	ON Adresse_adresseID_Log USING GIST(adresseID, adresseID_validite, adresseID_transaction);


--------Adresse localisation validité--------
CREATE TABLE IF NOT EXISTS Adresse_Localisation_Validite(
	adresseID INT NOT NULL,
	
	appartement Adresse_Appartement,
    rue Adresse_Rue NOT NULL,
    ville Adresse_Ville NOT NULL,
    region Adresse_Region NOT NULL,
	code_postal Adresse_CP NOT NULL,
    pays Adresse_Pays NOT NULL,

	Localisation_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Adresse_Localisation_Validite_INDEX
	ON Adresse_Localisation_Validite USING GIST(adresseID, Localisation_validite);

--Vérification
ALTER TABLE Adresse_Localisation_Validite
--Redondance
	ADD CONSTRAINT Adresse_Localisation_Validite_Redondance
		EXCLUDE USING GIST (adresseID WITH =,
							appartement WITH =,
							rue WITH =,
							ville WITH =,
							region WITH =,
							code_postal WITH =,
							pays WITH =,
							Localisation_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Adresse_Localisation_Validite
	ADD CONSTRAINT Adresse_Localisation_Validite_Circonlocution
		EXCLUDE USING GIST (adresseID WITH =,
							appartement WITH =,
							rue WITH =,
							ville WITH =,
							region WITH =,
							code_postal WITH =,
							pays WITH =,
							Localisation_validite WITH -|-);

--Contradiction
ALTER TABLE Adresse_Localisation_Validite
	ADD CONSTRAINT Adresse_Localisation_Validite_Contradiction
		EXCLUDE USING GIST (adresseID WITH =,
							appartement WITH <>,
							rue WITH <>,
							ville WITH <>,
							region WITH <>,
							code_postal WITH <>,
							pays WITH <>,
							Localisation_validite WITH &&);
		

--------Adresse localisation log--------
CREATE TABLE IF NOT EXISTS Adresse_Localisation_Log(
	adresseID INT NOT NULL,
	
	appartement Adresse_Appartement,
    rue Adresse_Rue NOT NULL,
    ville Adresse_Ville NOT NULL,
    region Adresse_Region NOT NULL,
	code_postal Adresse_CP NOT NULL,
    pays Adresse_Pays NOT NULL,
	
	Localisation_validite TSRANGE_sec NOT NULL,
	Localisation_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Adresse_Localisation_Log_INDEX
	ON Adresse_Localisation_Log USING GIST(adresseID, Localisation_validite, Localisation_transaction);
	


--------Étudiant courante--------
CREATE TABLE IF NOT EXISTS Etudiant_Courante(
	matricule Etudiant_Matricule NOT NULL,
	matricule_since Estampille NOT NULL,
	
	prenom nom_prenom NOT NULL,
	nom nom_prenom NOT NULL,
	nom_prenom_since Estampille NOT NULL, 

	courriel email NOT NULL UNIQUE,	
	telephone phoneNumber NOT NULL,
	contact_since Estampille NOT NULL,
	
	adresseID INT NOT NULL,
	adresseID_since Estampille NOT NULL,
	
	PRIMARY KEY (matricule)
	--FOREIGN KEY (adresseID) REFERENCES Adresse(adresseID)
);

--------Étudiant courante log--------
CREATE TABLE IF NOT EXISTS Etudiant_Courante_Log(
	matricule Etudiant_Matricule NOT NULL,
	matricule_since Estampille NOT NULL,
	
	prenom nom_prenom NOT NULL,
	nom nom_prenom NOT NULL,
	nom_prenom_since Estampille NOT NULL, 

	courriel email NOT NULL,
	telephone phoneNumber NOT NULL,
	contact_since Estampille NOT NULL,
	
	adresseID INT NOT NULL,
	adresseID_since Estampille NOT NULL,
	
	etudiant_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_Courante_Log_INDEX
	ON Etudiant_Courante_Log USING GIST(matricule, etudiant_transaction);



--------Étudiant matricule validité--------
CREATE TABLE IF NOT EXISTS Etudiant_Matricule_Validite(
	matricule Etudiant_Matricule NOT NULL,
	etudiant_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_Matricule_Validite_INDEX
	ON Etudiant_Matricule_Validite USING GIST(matricule, etudiant_validite);

--Vérification
ALTER TABLE Etudiant_Matricule_Validite
--Redondance
	ADD CONSTRAINT Etudiant_Matricule_Validite_Redondance
		EXCLUDE USING GIST (matricule WITH =, 
							etudiant_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Etudiant_Matricule_Validite
	ADD CONSTRAINT Etudiant_Matricule_Validite_Circonlocution
		EXCLUDE USING GIST (matricule WITH =, 
							etudiant_validite WITH -|-);

--Contradiction
--Sans objet, pas d'attribut non clé



--------Étudiant matricule log--------
CREATE TABLE IF NOT EXISTS Etudiant_Matricule_Log(
	matricule Etudiant_Matricule NOT NULL,
	etudiant_validite TSRANGE_sec NOT NULL,
	etudiant_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_Matricule_Log_INDEX
	ON Etudiant_Matricule_Log USING GIST(matricule, etudiant_validite, etudiant_transaction);



--------Étudiant nom, prénom validité--------
CREATE TABLE IF NOT EXISTS Etudiant_nom_prenom_Validite(
	matricule Etudiant_Matricule NOT NULL,
	
	prenom nom_prenom NOT NULL,
	nom nom_prenom NOT NULL,
	nom_prenom_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_nom_prenom_Validite_INDEX
	ON Etudiant_nom_prenom_Validite USING GIST(matricule, nom_prenom_validite);

--Vérification
ALTER TABLE Etudiant_nom_prenom_Validite
--Redondance
	ADD CONSTRAINT Etudiant_nom_prenom_Validite_Redondance
		EXCLUDE USING GIST (matricule WITH =,
							prenom WITH =,
							nom WITH =,
							nom_prenom_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Etudiant_nom_prenom_Validite
	ADD CONSTRAINT Etudiant_nom_prenom_Validite_Circonlocution
		EXCLUDE USING GIST (matricule WITH =,
							prenom WITH =,
							nom WITH =,
							nom_prenom_validite WITH -|-);

--Contradiction
ALTER TABLE Etudiant_nom_prenom_Validite
	ADD CONSTRAINT Etudiant_nom_prenom_Validite_Contradiction
		EXCLUDE USING GIST (matricule WITH =,
							prenom WITH <>,
							nom WITH <>,
							nom_prenom_validite WITH &&);
							
							
--------Étudiant nom, prénom log--------
CREATE TABLE IF NOT EXISTS Etudiant_nom_prenom_Log(
	matricule Etudiant_Matricule NOT NULL,
	
	prenom nom_prenom NOT NULL,
	nom nom_prenom NOT NULL,
	nom_prenom_validite TSRANGE_sec NOT NULL,
	nom_prenom_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_nom_prenom_Log_INDEX
	ON Etudiant_nom_prenom_Log USING GIST(matricule, nom_prenom_validite, nom_prenom_transaction);
	
	
	
--------Étudiant contact validité--------
CREATE TABLE IF NOT EXISTS Etudiant_contact_Validite(
	matricule Etudiant_Matricule NOT NULL,
	
	courriel email NOT NULL,
	telephone phoneNumber NOT NULL,
	contact_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_contact_Validite_INDEX
	ON Etudiant_contact_Validite USING GIST(matricule, contact_validite);

--Vérification
ALTER TABLE Etudiant_contact_Validite
--Redondance
	ADD CONSTRAINT Etudiant_contact_Validite_Redondance
		EXCLUDE USING GIST (matricule WITH =,
							courriel WITH =,
							telephone WITH =,
							contact_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Etudiant_contact_Validite
	ADD CONSTRAINT Etudiant_contact_Validite_Circonlocution
		EXCLUDE USING GIST (matricule WITH =,
							courriel WITH =,
							telephone WITH =,
							contact_validite WITH -|-);

--Contradiction
ALTER TABLE Etudiant_contact_Validite
	ADD CONSTRAINT Etudiant_contact_Validite_Contradiction
		EXCLUDE USING GIST (matricule WITH =,
							courriel WITH <>,
							telephone WITH <>,
							contact_validite WITH &&);
							
							
--------Étudiant contact log--------
CREATE TABLE IF NOT EXISTS Etudiant_contact_Log(
	matricule Etudiant_Matricule NOT NULL,
	
	courriel email NOT NULL,
	telephone phoneNumber NOT NULL,
	contact_validite TSRANGE_sec NOT NULL,
	contact_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_contact_Log_INDEX
	ON Etudiant_contact_Log USING GIST(matricule, contact_validite, contact_transaction);
	


--------Étudiant adresseID validité--------
CREATE TABLE IF NOT EXISTS Etudiant_adresseID_Validite(
	matricule Etudiant_Matricule NOT NULL,
	
	adresseID INT NOT NULL,
	adresseID_validite TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_adresseID_validite_INDEX
	ON Etudiant_adresseID_Validite USING GIST(matricule, adresseID_validite);

--Vérification
ALTER TABLE Etudiant_adresseID_Validite
--Redondance
	ADD CONSTRAINT Etudiant_adresseID_Validite_Redondance
		EXCLUDE USING GIST (matricule WITH =,
							adresseID WITH =,
							adresseID_validite WITH &&);
	
--Ciconcolocution
ALTER TABLE Etudiant_adresseID_Validite
	ADD CONSTRAINT Etudiant_adresseID_Validite_Circonlocution
		EXCLUDE USING GIST (matricule WITH =,
							adresseID WITH =,
							adresseID_validite WITH -|-);

--Contradiction
ALTER TABLE Etudiant_adresseID_Validite
	ADD CONSTRAINT Etudiant_adresseID_Validite_Contradiction
		EXCLUDE USING GIST (matricule WITH =,
							adresseID WITH <>,
							adresseID_validite WITH &&);
							
							
--------Étudiant adresseID log--------
CREATE TABLE IF NOT EXISTS Etudiant_adresseID_Log(
	matricule Etudiant_Matricule NOT NULL,
	
	adresseID INT NOT NULL,
	adresseID_validite TSRANGE_sec NOT NULL,
	adresseID_transaction TSRANGE_sec NOT NULL
);

CREATE INDEX IF NOT EXISTS Etudiant_adresseID_Log_INDEX
	ON Etudiant_adresseID_Log USING GIST(matricule, adresseID_validite, adresseID_transaction);


/*
-- ===========================================================================
Contributeurs :
(BOUM3688) Mohamed.Boubacar.Boureima@usherbrooke.ca 
(ELBO1901) Othman.El.Biyaali@USherbrooke.ca 
(SOUA2604) Alseny.Toumany.Soumah@usherbrooke.ca
(SOUM3004) Maxime.Sourceaux@usherbrooke.ca 

Adresse, droits d'auteur et copyright :
  Département d'informatique
  Faculté des sciences
  Université de Sherbrooke
  Sherbrooke (Québec)  J1K 2R1
  Canada
-- ===========================================================================
*/
