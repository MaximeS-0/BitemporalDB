/*
-- ===========================================================================
-- IFT723_cre_table_adresse.sql
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


SET SCHEMA 'IFT723';

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