/*
-- ===========================================================================
-- IFT723_cre_BD.sql
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
Résumé : Création de la base de données, comprenant les tables, les triggers, les fonctions et l’API.
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
	
	PRIMARY KEY (matricule),
	FOREIGN KEY (adresseID) REFERENCES Adresse_Courante(adresseID)
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


--------Définition des triggers--------
--------Table adresse--------
--------Triggger pour sauvegarder dans les tables de logs--------
--------Trigger de la table Adresse_courante--------
CREATE OR REPLACE FUNCTION Adresse_courante_sauvegarde_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Adresse_Courante_Log (adresseID, 
										  adresseID_since, 
										  appartement,
										  rue, 
										  ville, 
										  region, 
										  code_postal, 
										  pays, 
										  Localisation_since, 
										  adresse_transaction)
										   
		VALUES (NEW.adresseID, 
				NEW.adresseID_since, 
				NEW.appartement, 
				NEW.rue,
				NEW.ville,
				NEW.region, 
				NEW.code_postal,
				NEW.pays,
				NEW.Localisation_since,
				TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
			   );
		RETURN NEW;
		
    ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du adresseID
		IF OLD.adresseID != NEW.adresseID THEN
			RAISE EXCEPTION 'CANT MODIFY ADRESSEID';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT adresse_transaction INTO range1 FROM Adresse_Courante_Log WHERE adresseID = OLD.adresseID AND (UPPER(adresse_transaction) IS NULL);
		
		UPDATE Adresse_Courante_Log
		SET adresse_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(adresse_transaction) IS NULL);

        --On insère une ligne
		INSERT INTO Adresse_Courante_Log (adresseID, 
										  adresseID_since, 
										  appartement,
										  rue, 
										  ville, 
										  region, 
										  code_postal, 
										  pays, 
										  Localisation_since, 
										  adresse_transaction)
										   
		VALUES (NEW.adresseID, 
				NEW.adresseID_since, 
				NEW.appartement, 
				NEW.rue,
				NEW.ville,
				NEW.region, 
				NEW.code_postal,
				NEW.pays,
				NEW.Localisation_since,
				TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
			   );
		RETURN NEW;


    ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT adresse_transaction INTO range1 FROM Adresse_Courante_Log WHERE adresseID = OLD.adresseID AND (UPPER(adresse_transaction) IS NULL);
		
		UPDATE Adresse_Courante_Log
		SET adresse_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(adresse_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER Adresse_courante_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Adresse_Courante FOR EACH ROW EXECUTE PROCEDURE Adresse_courante_sauvegarde_Log();



--------Trigger de la table Adresse_AdresseID--------
CREATE OR REPLACE FUNCTION Adresse_adresseID_sauvegarde_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Adresse_adresseID_Log (adresseID,
                                           adresseID_validite,
	                                       adresseID_transaction)
		VALUES (
			NEW.adresseID,
			NEW.adresseID_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du adresseID
		IF OLD.adresseID != NEW.adresseID THEN
			RAISE EXCEPTION 'CANT MODIFY ADRESSEID';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT adresseID_transaction INTO range1 FROM Adresse_adresseID_Log WHERE adresseID = OLD.adresseID AND (UPPER(adresseID_transaction) IS NULL);
		
		UPDATE Adresse_adresseID_Log
		SET adresseID_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(adresseID_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Adresse_adresseID_Log (adresseID,
                                           adresseID_validite,
	                                       adresseID_transaction)
		VALUES (
			NEW.adresseID,
			NEW.adresseID_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT adresseID_transaction INTO range1 FROM Adresse_adresseID_Log WHERE adresseID = OLD.adresseID AND (UPPER(adresseID_transaction) IS NULL);
		
		UPDATE Adresse_adresseID_Log
		SET adresseID_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(adresseID_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Adresse_adresseID_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Adresse_adresseID_Validite FOR EACH ROW EXECUTE PROCEDURE Adresse_adresseID_sauvegarde_Log();




--------Trigger de la table Adresse_Rue_Ville_Region_Pays --------
CREATE OR REPLACE FUNCTION Adresse_Localisation_sauvegarde_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO adresse_Localisation_Log (adresseID,
											  appartement,  
											  rue, 
											  ville,
											  region,
											  code_postal,
											  pays,
											  Localisation_validite,
											  Localisation_transaction
											 )
		VALUES (
			NEW.adresseID,
			NEW.appartement,
			NEW.rue,
			NEW.ville,
			NEW.region,
			NEW.code_postal,
			NEW.pays,
			NEW.Localisation_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du adresseID
		IF OLD.adresseID != NEW.adresseID THEN
			RAISE EXCEPTION 'CANT MODIFY ADRESSEID';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT Localisation_transaction INTO range1 FROM Adresse_Localisation_Log WHERE adresseID = OLD.adresseID AND (UPPER(Localisation_transaction) IS NULL);
		
		UPDATE Adresse_Localisation_Log
		SET Localisation_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(Localisation_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO adresse_Localisation_Log (adresseID,
											  appartement,  
											  rue, 
											  ville,
											  region,
											  code_postal,
											  pays,
											  Localisation_validite,
											  Localisation_transaction
											 )
		VALUES (
			NEW.adresseID,
			NEW.appartement,
			NEW.rue,
			NEW.ville,
			NEW.region,
			NEW.code_postal,
			NEW.pays,
			NEW.Localisation_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT Localisation_transaction INTO range1 FROM Adresse_Localisation_Log WHERE adresseID = OLD.adresseID AND (UPPER(Localisation_transaction) IS NULL);
		
		UPDATE Adresse_Localisation_Log
		SET Localisation_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE adresseID = OLD.adresseID AND (UPPER(Localisation_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER Adresse_Localisation_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Adresse_Localisation_Validite FOR EACH ROW EXECUTE PROCEDURE Adresse_Localisation_Sauvegarde_Log();

		

--------Table Etudiant--------
--------Triggger pour sauvegarder dans les tables de logs--------
--------Trigger de la table Etudiant_courante--------
CREATE OR REPLACE FUNCTION Etudiant_courante_sauvegarde_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Etudiant_Courante_Log (matricule, 
										   matricule_since, 
										   prenom, 
										   nom, 
										   nom_prenom_since,
										   courriel, 
										   telephone, 
										   contact_since, 
										   adresseID, 
										   adresseID_since, 
										   etudiant_transaction)
		VALUES (
			NEW.matricule,
			NEW.matricule_since,
			NEW.prenom,
			NEW.nom,
			NEW.nom_prenom_since,
			NEW.courriel,
			NEW.telephone,
			NEW.contact_since,
			NEW.adresseID,
			NEW.adresseID_since,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du matricule
		IF OLD.matricule != NEW.matricule THEN
			RAISE EXCEPTION 'CANT MODIFY MATRICULE';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT etudiant_transaction INTO range1 FROM Etudiant_Courante_Log WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		UPDATE Etudiant_Courante_Log
		SET etudiant_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Etudiant_Courante_Log (matricule, 
										   matricule_since, 
										   prenom, 
										   nom, 
										   nom_prenom_since,
										   courriel, 
										   telephone, 
										   contact_since, 
										   adresseID, 
										   adresseID_since, 
										   etudiant_transaction)
		VALUES (
			NEW.matricule,
			NEW.matricule_since,
			NEW.prenom,
			NEW.nom,
			NEW.nom_prenom_since,
			NEW.courriel,
			NEW.telephone,
			NEW.contact_since,
			NEW.adresseID,
			NEW.adresseID_since,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT etudiant_transaction INTO range1 FROM Etudiant_Courante_Log WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		UPDATE Etudiant_Courante_Log
		SET etudiant_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Etudiant_courante_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Etudiant_Courante FOR EACH ROW EXECUTE PROCEDURE Etudiant_courante_sauvegarde_Log();


--------Trigger de la table Etudiant_matricule--------
CREATE OR REPLACE FUNCTION Etudiant_matricule_validite_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Etudiant_Matricule_Log (matricule,
											etudiant_validite,
											etudiant_transaction)
		VALUES (
			NEW.matricule,
			NEW.etudiant_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du matricule
		IF OLD.matricule != NEW.matricule THEN
			RAISE EXCEPTION 'CANT MODIFY MATRICULE';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT etudiant_transaction INTO range1 FROM Etudiant_Matricule_Log WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		UPDATE Etudiant_Matricule_Log
		SET etudiant_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Etudiant_Matricule_Log (matricule,
											etudiant_validite,
											etudiant_transaction)
		VALUES (
			NEW.matricule,
			NEW.etudiant_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT etudiant_transaction INTO range1 FROM Etudiant_Matricule_Log WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		UPDATE Etudiant_Matricule_Log
		SET etudiant_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(etudiant_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Etudiant_matricule_validite_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Etudiant_matricule_validite FOR EACH ROW EXECUTE PROCEDURE Etudiant_matricule_validite_Log();


--------Trigger de la table Etudiant_nom_prenom--------
CREATE OR REPLACE FUNCTION Etudiant_nom_prenom_validite_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Etudiant_nom_prenom_Log (matricule,
											 prenom,
											 nom,
											 nom_prenom_validite,
											 nom_prenom_transaction
											)
		VALUES (
			NEW.matricule,
			NEW.prenom,
			NEW.nom,
			NEW.nom_prenom_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du matricule
		IF OLD.matricule != NEW.matricule THEN
			RAISE EXCEPTION 'CANT MODIFY MATRICULE';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT nom_prenom_transaction INTO range1 FROM Etudiant_nom_prenom_Log WHERE matricule = OLD.matricule AND (UPPER(nom_prenom_transaction) IS NULL);
		
		UPDATE Etudiant_nom_prenom_Log
		SET nom_prenom_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(nom_prenom_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Etudiant_nom_prenom_Log (matricule,
											 prenom,
											 nom,
											 nom_prenom_validite,
											 nom_prenom_transaction
											)
		VALUES (
			NEW.matricule,
			NEW.prenom,
			NEW.nom,
			NEW.nom_prenom_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT nom_prenom_transaction INTO range1 FROM Etudiant_nom_prenom_Log WHERE matricule = OLD.matricule AND (UPPER(nom_prenom_transaction) IS NULL);
		
		UPDATE Etudiant_nom_prenom_Log
		SET nom_prenom_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(nom_prenom_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Etudiant_nom_prenom_validite_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Etudiant_nom_prenom_validite FOR EACH ROW EXECUTE PROCEDURE Etudiant_nom_prenom_validite_Log();


--------Trigger de la table Etudiant_contact--------
CREATE OR REPLACE FUNCTION Etudiant_contact_validite_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Etudiant_contact_Log (matricule,
										  courriel,
										  telephone,
										  contact_validite,
										  contact_transaction
										 )
		VALUES (
			NEW.matricule,
			NEW.courriel,
			NEW.telephone,
			NEW.contact_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du matricule
		IF OLD.matricule != NEW.matricule THEN
			RAISE EXCEPTION 'CANT MODIFY MATRICULE';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT contact_transaction INTO range1 FROM Etudiant_contact_Log WHERE matricule = OLD.matricule AND (UPPER(contact_transaction) IS NULL);
		
		UPDATE Etudiant_contact_Log
		SET contact_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(contact_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Etudiant_contact_Log (matricule,
										  courriel,
										  telephone,
										  contact_validite,
										  contact_transaction
										 )
		VALUES (
			NEW.matricule,
			NEW.courriel,
			NEW.telephone,
			NEW.contact_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT contact_transaction INTO range1 FROM Etudiant_contact_Log WHERE matricule = OLD.matricule AND (UPPER(contact_transaction) IS NULL);
		
		UPDATE Etudiant_contact_Log
		SET contact_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(contact_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Etudiant_contact_validite_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Etudiant_contact_validite FOR EACH ROW EXECUTE PROCEDURE Etudiant_contact_validite_Log();

--------Trigger de la table Etudiant_adresseID--------
CREATE OR REPLACE FUNCTION Etudiant_adresseID_validite_Log() RETURNS TRIGGER AS $$
DECLARE
	range1 TSRANGE;
	
BEGIN	
	IF TG_OP = 'INSERT' THEN --Dans le cas d'un insert
		--Lors d'une insertion, on doit créer la ligne dans le log de la table courante
		--On ajoute dans la table de log
		INSERT INTO Etudiant_adresseID_Log (matricule,
										  	adresseID,
											adresseID_validite,
										  	adresseID_transaction
										 )
		VALUES (
			NEW.matricule,
			NEW.adresseID,
			NEW.adresseID_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		RETURN NEW;
		
	ELSIF TG_OP = 'UPDATE' THEN --Dans le cas d'un update
	
		--On ne permet pas la modification du matricule
		IF OLD.matricule != NEW.matricule THEN
			RAISE EXCEPTION 'CANT MODIFY MATRICULE';
			RETURN NULL;
		END IF;
		
		
		--Lors d'un upadte, il faut fermer le tuple correspondant dans la table de log, puis ouvrir une nouvelle ligne
		--On ferme la ligne
		SELECT adresseID_transaction INTO range1 FROM Etudiant_adresseID_Log WHERE matricule = OLD.matricule AND (UPPER(adresseID_transaction) IS NULL);
		
		UPDATE Etudiant_adresseID_Log
		SET adresseID_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(adresseID_transaction) IS NULL);
					
		--On insère une ligne
		INSERT INTO Etudiant_adresseID_Log (matricule,
										  	adresseID,
											adresseID_validite,
										  	adresseID_transaction
										 )
		VALUES (
			NEW.matricule,
			NEW.adresseID,
			NEW.adresseID_validite,
			TSRANGE_sec(NOW()::TIMESTAMP, NULL, '[)')
		);
		
		RETURN NEW;
		
	ELSE --Dans le cas d'un delete
		--Lors d'un delete, il faut fermer le tuple correspondant dans la table de log de la table courante.
		SELECT adresseID_transaction INTO range1 FROM Etudiant_adresseID_Log WHERE matricule = OLD.matricule AND (UPPER(adresseID_transaction) IS NULL);
		
		UPDATE Etudiant_adresseID_Log
		SET adresseID_transaction = TSRANGE_sec(lower(range1), NOW()::TIMESTAMP, '[)')
		WHERE matricule = OLD.matricule AND (UPPER(adresseID_transaction) IS NULL);
		
		RETURN OLD;
		
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Etudiant_adresseID_validite_sauvegarde_Log_Trigger BEFORE INSERT OR UPDATE OR DELETE
ON Etudiant_adresseID_validite FOR EACH ROW EXECUTE PROCEDURE Etudiant_adresseID_validite_Log();



--------Table Adresse--------
-------------------------------------------------------
--------Fonction pour la modification des tables de validités--------
--------Permet d'ajouter dans toutes les tables de validité---------
--Si on ajoute dans seulement une seule table, c'est comme si les autres attributs étaient nul durant la période. Ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut ajouter dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE adresse_validite_ajout(adresseID_ INT,
												   appartement_ Adresse_Appartement,
												   rue_ Adresse_Rue,
												   ville_ Adresse_Ville,
												   region_ Adresse_Region,
												   code_postal_ Adresse_CP,
												   pays_ Adresse_Pays,
												   date_debut_ Estampille,
												   date_fin_ Estampille
												  )
															 
AS $$
DECLARE 
	rangeAjout TSRANGE_sec;
	rangeAdjacentGauche TSRANGE_sec;
	rangeAdjacentDroite TSRANGE_sec;
BEGIN	
	
	IF (date_debut_ >= date_fin_) THEN
		RAISE EXCEPTION 'LA DATE DE FIN DOIT ETRE APRES LA DATE DE DEBUT';
		RETURN;
	END IF;
	
	rangeAjout = TSRANGE_sec(date_debut_, date_fin_, '[)');
	
	--Vérification s'il y a un chevauchement; 
		--Si oui, on arrete la procédure : On doit passer par un update
		--Si non, on coninue.
		
	--Vérification s'il y a des tuples adjacents; 
		--Si oui, on combine les tuples.
		--Si non, on ajoute les tuples normalement. 


	--Vérification de chevauchement
		IF 
			(SELECT adresseID FROM Adresse_adresseID_Validite WHERE adresseID = adresseID_ AND rangeAjout && adresseID_validite) IS NOT NULL
			 OR
			(SELECT adresseID FROM Adresse_Localisation_Validite WHERE adresseID = adresseID_ AND rangeAjout && Localisation_validite) IS NOT NULL
		THEN
			RAISE EXCEPTION 'CHEVAUCHEMENT DE DONNEES; UTILISER UN UPDATE';
			RETURN;
		END IF;	


	--Adresse_AdresseID--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT adresseID_validite INTO rangeAdjacentGauche FROM Adresse_adresseID_Validite WHERE adresseID = adresseID_ AND rangeAjout -|- adresseID_validite AND adresseID_validite << rangeAjout;
	SELECT adresseID_validite INTO rangeAdjacentDroite FROM Adresse_adresseID_Validite WHERE adresseID = adresseID_ AND rangeAjout -|- adresseID_validite AND adresseID_validite >> rangeAjout;
	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rangeAdjacentGauche);
		CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rangeAdjacentDroite);
		CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));
		

	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rangeAdjacentGauche);
		CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rangeAdjacentDroite);
		CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, date_debut_, date_fin_);
		
	END IF;
	
	
	
	--Etudiant_Localisation--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT Localisation_validite INTO rangeAdjacentGauche FROM Adresse_Localisation_Validite WHERE adresseID = adresseID_ AND appartement = appartement_ AND rue = rue_ AND ville = ville_ AND region = region_ AND code_postal = code_postal_ AND pays = pays_ AND rangeAjout -|- Localisation_validite AND Localisation_validite << rangeAjout;
	SELECT Localisation_validite INTO rangeAdjacentDroite FROM Adresse_Localisation_Validite WHERE adresseID = adresseID_ AND appartement = appartement_ AND rue = rue_ AND ville = ville_ AND region = region_ AND code_postal = code_postal_ AND pays = pays_ AND rangeAjout -|- Localisation_validite AND Localisation_validite >> rangeAjout;

	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rangeAdjacentGauche);
		CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rangeAdjacentDroite);
		CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, appartement_, rue_, ville_, region_, code_postal_, pays_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));

		
	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rangeAdjacentGauche);
		CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, appartement_, rue_, ville_, region_, code_postal_, pays_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rangeAdjacentDroite);
		CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, appartement_, rue_, ville_, region_, code_postal_, pays_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, appartement_, rue_, ville_, region_, code_postal_, pays_, date_debut_, date_fin_);
		
	END IF;

		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour toutes les tables de validité---------
--Si on modifie dans seulement une seule table, il se pourrait que certains attributs soient NULL pour certaine période, ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut modifier dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE adresse_validite_modification(adresseID_ INT,
														   appartement_ Adresse_Appartement,
														   rue_ Adresse_Rue,
														   ville_ Adresse_Ville,
														   region_ Adresse_Region,
														   code_postal_ Adresse_CP,
														   pays_ Adresse_Pays,
														   date_debut_ Estampille,
														   date_fin_ Estampille
														   )
		
AS $$
DECLARE 

BEGIN	
	
	--Un update est l'équivalent d'effacer puis de ré-insérer
	call adresse_validite_effacer(adresseID_, date_debut_, date_fin_);
	call adresse_validite_ajout(adresseID_, appartement_, rue_, ville_, region_, code_postal_, pays_, date_debut_, date_fin_);

END;
$$ LANGUAGE plpgsql;



--------Permet d'effacer dans toutes les tables de validité---------
--Si on efface dans seulement une seule table, il se pourrait que certains attributs soient NULL pour certaine période, ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut effacer dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE adresse_validite_effacer(adresseID_ INT,
													 date_effacement_debut_ Estampille,
													 date_effacement_fin_ Estampille
													)
															 
AS $$
DECLARE 
	rangeEffacement TSRANGE_sec;
	rec RECORD;
BEGIN	
	IF (date_effacement_debut_ >= date_effacement_fin_) THEN
		RAISE EXCEPTION 'LA DATE DE FIN DOIT ETRE APRES LA DATE DE DEBUT';
		RETURN;
	END IF;
	
	
	rangeEffacement = TSRANGE_sec(date_effacement_debut_, date_effacement_fin_, '[)');
		
		
	--À faire pour toutes les tables de validitées
	
	--Si le nouveau range est contenu dans un autre tuple : On sépare l'ancien tuple entre avant et après; Situation unique
	--Ancien   : ==========
	--Effacer  :    ====
	--Résultat : ===    ===
	
	--Si des elements sont contenus dans le range : On les effaces; Peut arriver sur plusieurs tuples
	--Ancien 1 :     ====
	--Ancien 2 :		 =====
	--Effacer  :    ===========
	--Résultat :    	
	
	--S'il y a chevauchement & ne s'étend pas sur la droite : On modifie l'ancien tuple jusqu'au début de l'effacement; Situation unique
    --Ancien   : =======
	--Effacer  :      =====
	--Résultat : =====
	
	--S'il y a chevauchement & ne s'étend pas sur la gauche : On modifie l'ancien tuple jusqu'à la fin de l'effacement; Situation unique
    --Ancien   :    =======
	--Effacer  : =====
	--Résultat :      =====
	
	
	
	 	------AdresseID_validite------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Adresse_adresseID_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement <@ adresseID_validite
		LOOP
			CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rec.adresseID_validite);
			CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, lower(rec.adresseID_validite), date_effacement_debut_);
			CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, date_effacement_fin_, upper(rec.adresseID_validite));
		END LOOP;

		
		--Element contenu dans le range--
		FOR rec IN SELECT * 
				   FROM Adresse_adresseID_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement @> adresseID_validite
		LOOP
			CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rec.adresseID_validite);			
		END LOOP;
		
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Adresse_adresseID_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement && adresseID_validite AND adresseID_validite &< rangeEffacement
		LOOP
			CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rec.adresseID_validite);
			CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, lower(rec.adresseID_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Adresse_adresseID_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement && adresseID_validite AND adresseID_validite &> rangeEffacement
		LOOP
			CALL Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_, rec.adresseID_validite);
			CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, date_effacement_fin_, upper(rec.adresseID_validite));
		END LOOP;
		
		
		------localisation_validité------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Adresse_Localisation_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement <@ Localisation_validite
		LOOP
			CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rec.Localisation_validite);
			CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, rec.appartement, rec.rue, rec.ville, rec.region, rec.code_postal, rec.pays, lower(rec.Localisation_validite), date_effacement_debut_);
			CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, rec.appartement, rec.rue, rec.ville, rec.region, rec.code_postal, rec.pays, date_effacement_fin_, upper(rec.Localisation_validite));
		END LOOP;

		
		--Element contenu dans le range--
				FOR rec IN SELECT * 
				   FROM Adresse_Localisation_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement @> Localisation_validite
		LOOP
			CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rec.Localisation_validite);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Adresse_Localisation_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement && Localisation_validite AND Localisation_validite &< rangeEffacement
		LOOP
			CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rec.Localisation_validite);
			CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, rec.appartement, rec.rue, rec.ville, rec.region, rec.code_postal, rec.pays, lower(rec.Localisation_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Adresse_Localisation_Validite 
				   WHERE adresseID = adresseID_ AND rangeEffacement && Localisation_validite AND Localisation_validite &> rangeEffacement
		LOOP
			CALL etudiant_Localisation_validite_effacer_PRIVATE(adresseID_, rec.Localisation_validite);
			CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_, rec.appartement, rec.rue, rec.ville, rec.region, rec.code_postal, rec.pays, date_effacement_fin_, upper(rec.Localisation_validite));
		END LOOP;
		
END;
$$ LANGUAGE plpgsql;




-------------------------------------------------------
--------Permet d'ajouter dans la table courante--------
--------Permet d'ajouter à un moment précis--------
CREATE OR REPLACE PROCEDURE Adresse_Courante_ajout_at(adresseID_ INT,
													  appartement_ Adresse_Appartement,
													  rue_ Adresse_Rue,
													  ville_ Adresse_Ville,
													  region_ Adresse_Region,
													  code_postal_ Adresse_CP,
													  pays_ Adresse_Pays,
													  date_ajout_ Estampille
													  )
AS $$
BEGIN	

	--On vérifie que la date d'ajout est plus grande que les dates pour la même clé dans les tables de validité
	--On ne peut pas ajouter un tuple valide qui est plus vieux qu'un tuple fermé
	--TO DO
	
	INSERT INTO Adresse_Courante(adresseID,
								 adresseID_since, 
								 appartement,
								 rue,
								 ville,
								 region, 
								 code_postal,
								 pays,
								 Localisation_since
								 )
		VALUES (
			adresseID_,
			date_ajout_,
			appartement_,
			rue_,
			ville_,
			region_,
			code_postal_,
			pays_,
			date_ajout_
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet d'ajouter maintenant--------
CREATE OR REPLACE PROCEDURE Adresse_Courante_ajout_now(adresseID_ INT,
													   appartement_ Adresse_Appartement,
													   rue_ Adresse_Rue,
													   ville_ Adresse_Ville,
													   region_ Adresse_Region,
													   code_postal_ Adresse_CP,
													   pays_ Adresse_Pays
													   )
AS $$
BEGIN	
	
	CALL Adresse_Courante_ajout_at(adresseID_, 
								   appartement_, 
								   rue_, 
								   ville_, 
								   region_, 
								   code_postal_,
								   pays_,
								   NOW()::Estampille);

END;
$$ LANGUAGE plpgsql;



--Permet de modifier le nom ou le prénom dans la table courante--
--Permet de modifier à un moment précis
CREATE OR REPLACE PROCEDURE Adresse_Courante_modifier_Localisation_at(adresseID_ INT,
													  				  appartement_ Adresse_Appartement,
																	  rue_ Adresse_Rue,
																	  ville_ Adresse_Ville,
																	  region_ Adresse_Region,
																	  code_postal_ Adresse_CP,
																	  pays_ Adresse_Pays,
																	  date_changement Estampille
																	 )
AS $$
DECLARE
	appartement_avant Adresse_Appartement;
	rue_avant Adresse_Rue;
	ville_avant Adresse_Ville;
	region_avant Adresse_Region;
	code_postal_avant Adresse_CP;
	pays_avant Adresse_Pays;
	Localisation_since_avant Estampille;
	
BEGIN	
	
	--La date de retrait ne peut qu'être après la date initiale
	SELECT appartement, rue, ville, region, code_postal, pays, Localisation_since INTO appartement_avant, rue_avant, ville_avant, region_avant,code_postal_avant, pays_avant, Localisation_since_avant
	FROM Adresse_Courante WHERE adresseID = adresseID_;
	
	IF (Localisation_since_avant >= date_changement) THEN
		RAISE EXCEPTION 'LA DATE DOIT ETRE APRES LA DATE COURANTE';
		RETURN;
	END IF;
	
	--Sauvegarde de l'ancienne valeur dans la table de validité
	CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_,
													  appartement_avant,
													  rue_avant,
													  ville_avant,
													  region_avant,
													  code_postal_avant,
													  pays_avant,
													  Localisation_since_avant,
													  date_changement);
													
	--Modification dans la table courante
	UPDATE Adresse_Courante SET appartement = appartement_, rue = rue_, ville = ville_, region = region_, code_postal = code_postal_, pays = pays_, Localisation_since = date_changement   WHERE adresseID = adresseID_;
	
END;
$$ LANGUAGE plpgsql;


--Permet de modifier maintenant
CREATE OR REPLACE PROCEDURE Adresse_Courante_modifier_Localisation_now(adresseID_ INT,
													  				   appartement_ Adresse_Appartement,
																	   rue_ Adresse_Rue,
																	   ville_ Adresse_Ville,
																	   region_ Adresse_Region,
																	   code_postal_ Adresse_CP,
																	   pays_ Adresse_Pays
																	  )
AS $$
BEGIN	
	
	CALL Adresse_Courante_modifier_Localisation_at(adresseID_,
												  appartement_, 
												  rue_, 
												  ville_,
												  region_,
												  code_postal_,
												  pays_,
												  NOW()::Estampille
												  );
	
END;
$$ LANGUAGE plpgsql;


--Permet d'effacer de la table courante
--Permet d'effacer à un moment précis
CREATE OR REPLACE PROCEDURE Adresse_Courante_retrait_at(adresseID_ INT,
													  	date_retrait_ Estampille
													    )
AS $$
DECLARE
	adresseID_since_ Estampille;
	
	appartement_ Adresse_Appartement;
	rue_ Adresse_Rue;
	ville_ Adresse_Ville;
	region_ Adresse_Region;
	code_postal_ Adresse_CP;
	pays_ Adresse_Pays;
	Localisation_since_ Estampille;


BEGIN	
	
	
	SELECT adresseID_since,  
		   appartement,
		   rue,
		   ville,
		   region,
		   code_postal,
		   pays,
		   Localisation_since
		   
	INTO adresseID_since_,
	     appartement_,
		 rue_,
		 ville_,
		 region_,
		 code_postal_,
		 pays_,
		 Localisation_since_
		 
	FROM Adresse_Courante WHERE adresseID = adresseID_;
	
	--La date de retrait ne peut qu'être après les dates d'ajout
	IF (GREATEST(adresseID_since_, Localisation_since_) >= date_retrait_) THEN
		RAISE EXCEPTION 'LA DATE D EFFACEMENT DOIT ETRE APRES LES DATES D AJOUT';
		RETURN;
	END IF;
	
	--Sauvegarde des données dans les tables de validitées
	--Sauvegarde de l'adresseID	
	CALL Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_, 
										          adresseID_since_, 
										          date_retrait_);
	
	--Sauvegarde de la localisation
	CALL etudiant_Localisation_validite_ajout_PRIVATE(adresseID_,
													  appartement_,
													  rue_,
													  ville_,
													  region_,
													  code_postal_,
													  pays_,
													  Localisation_since_,
													  date_retrait_);


	--On efface la ligne dans la table courante
	DELETE FROM Adresse_Courante WHERE adresseID = adresseID_;
	
END;
$$ LANGUAGE plpgsql;

--Permet d'effacer maintenant
CREATE OR REPLACE PROCEDURE Adresse_Courante_retrait_now(adresseID_ INT)
AS $$

BEGIN	
	CALL Adresse_Courante_retrait_at(adresseID_, 
									 NOW()::Estampille);
	
END;
$$ LANGUAGE plpgsql;





-------------------------------------------------------
--------Table privé--------
--------Adresse_AdresseID--------
--------Permet d'ajouter dans la table Adresse_AdresseID--------
CREATE OR REPLACE PROCEDURE Adresse_adresseID_Validite_ajout_PRIVATE(adresseID_ INT,
															         date_debut Estampille,
															  		 date_fin Estampille
															         )
															 
AS $$
BEGIN	

	INSERT INTO Adresse_adresseID_Validite(adresseID,
										   adresseID_validite
										   )
		VALUES (
			adresseID_,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;

--------Permet de mettre à jour un tuple dans la table Etudiant_matricule--------
CREATE OR REPLACE PROCEDURE Adresse_adresseID_Validite_modification_PRIVATE(adresseID_ INT,
															                range_date_initiale TSRANGE_sec,
																		    date_debut_nouveau Estampille,
																	        date_fin_nouveau Estampille
															                )
															 
AS $$
BEGIN	

	UPDATE Adresse_adresseID_Validite
	SET adresseID_Validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE adresseID = adresseID_ AND
	      adresseID_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Etudiant_matricule--------
CREATE OR REPLACE PROCEDURE Adresse_adresseID_Validite_effacer_PRIVATE(adresseID_ INT,
															           range_date TSRANGE_sec
															           )
															 
AS $$
BEGIN	

	DELETE FROM Adresse_adresseID_Validite
	WHERE adresseID = adresseID_ AND
	      adresseID_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;



--------Adresse_Localisation--------
--------Permet d'ajouter dans la table Adresse_Localisation--------
CREATE OR REPLACE PROCEDURE etudiant_Localisation_validite_ajout_PRIVATE(adresseID_ INT,
																		 appartement_ Adresse_Appartement,
																		 rue_ Adresse_Rue,
																		 ville_ Adresse_Ville,
																		 region_ Adresse_Region,
																		 code_postal_ Adresse_CP,
																		 pays_ Adresse_Pays,
																		 date_debut Estampille,
															  		 	 date_fin Estampille
																		)
															 
AS $$
BEGIN	

	INSERT INTO Adresse_Localisation_Validite(adresseID,
											  appartement,  
											  rue, 
											  ville,
											  region,
											  code_postal,
											  pays,
											  Localisation_validite
											 )
		VALUES (
			adresseID_,
			appartement_,
			rue_,
			ville_,
			region_,
			code_postal_,
			pays_,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour un tuple dans la table Adresse_Localisation--------
CREATE OR REPLACE PROCEDURE etudiant_Localisation_validite_modification_PRIVATE(adresseID_ INT,
																				range_date_initiale TSRANGE_sec,
																				appartement_nouveau Adresse_Appartement,
																		 		rue_nouveau Adresse_Rue,
																		 		ville_nouveau Adresse_Ville,
																		 		region_nouveau Adresse_Region,
																		 		code_postal_nouveau Adresse_CP,
																		 		pays_nouveau Adresse_Pays,
																		 		date_debut_nouveau Estampille,
															  		 	 		date_fin_nouveau Estampille
															                	)
															 
AS $$
BEGIN	

	UPDATE Adresse_Localisation_Validite
	SET appartement = appartement_nouveau,
		rue = rue_nouveau, 
		ville = ville_nouveau,
		region = region_nouveau,
		code_postal = code_postal_nouveau,
		pays = pays_nouveau,
	    Localisation_validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE adresseID = adresseID_ AND
	      Localisation_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Adresse_Localisation--------
CREATE OR REPLACE PROCEDURE etudiant_Localisation_validite_effacer_PRIVATE(adresseID_ INT,
															               range_date TSRANGE_sec
															               )
															 
AS $$
BEGIN	

	DELETE FROM Adresse_Localisation_Validite
	WHERE adresseID = adresseID_ AND
	      Localisation_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;




--------Table Etudiant--------
-------Fonction pour la modification des tables de validités--------
--------Permet d'ajouter dans toutes les tables de validité---------
--Si on ajoute dans seulement une seule table, c'est comme si les autres attributs étaient nul durant la période. Ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut ajouter dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE etudiant_validite_ajout(matricule_ Etudiant_Matricule,
													prenom_ nom_prenom, 
													nom_ nom_prenom, 
													courriel_ email, 
													telephone_ phoneNumber,
													adresseID_ INT,
													date_debut_ Estampille,
													date_fin_ Estampille
													)
															 
AS $$
DECLARE 
	rangeAjout TSRANGE_sec;
	rangeAdjacentGauche TSRANGE_sec;
	rangeAdjacentDroite TSRANGE_sec;
BEGIN	
	
	IF (date_debut_ >= date_fin_) THEN
		RAISE EXCEPTION 'LA DATE DE FIN DOIT ETRE APRES LA DATE DE DEBUT';
		RETURN;
	END IF;
	
	rangeAjout = TSRANGE_sec(date_debut_, date_fin_, '[)');
	
	--Vérification s'il y a un chevauchement; 
		--Si oui, on arrete la procédure : On doit passer par un update
		--Si non, on coninue.
		
	--Vérification s'il y a des tuples adjacents; 
		--Si oui, on combine les tuples.
		--Si non, on ajoute les tuples normalement. 


	--Vérification de chevauchement
		IF 
			(SELECT matricule FROM Etudiant_Matricule_Validite WHERE matricule = matricule_ AND rangeAjout && etudiant_validite) IS NOT NULL
			 OR
			(SELECT matricule FROM Etudiant_nom_prenom_Validite WHERE matricule = matricule_ AND rangeAjout && nom_prenom_validite) IS NOT NULL
			 OR
			(SELECT matricule FROM Etudiant_contact_Validite WHERE matricule = matricule_ AND rangeAjout && contact_validite) IS NOT NULL
			 OR
			(SELECT matricule FROM Etudiant_adresseID_Validite WHERE matricule = matricule_ AND rangeAjout && adresseID_validite) IS NOT NULL		
		THEN
			RAISE EXCEPTION 'CHEVAUCHEMENT DE DONNEES; UTILISER UN UPDATE';
			RETURN;
		END IF;	


	--Etudiant_matricule--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT etudiant_validite INTO rangeAdjacentGauche FROM Etudiant_Matricule_Validite WHERE matricule = matricule_ AND rangeAjout -|- etudiant_validite AND etudiant_validite << rangeAjout;
	SELECT etudiant_validite INTO rangeAdjacentDroite FROM Etudiant_Matricule_Validite WHERE matricule = matricule_ AND rangeAjout -|- etudiant_validite AND etudiant_validite >> rangeAjout;
	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));
		
		
	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, date_debut_, date_fin_);
		
	END IF;
	
	
	
	--Etudiant_nom_prenom--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT nom_prenom_validite INTO rangeAdjacentGauche FROM Etudiant_nom_prenom_Validite WHERE matricule = matricule_ AND prenom = prenom_ AND nom = nom_ AND rangeAjout -|- nom_prenom_validite AND nom_prenom_validite << rangeAjout;
	SELECT nom_prenom_validite INTO rangeAdjacentDroite FROM Etudiant_nom_prenom_Validite WHERE matricule = matricule_ AND prenom = prenom_ AND nom = nom_ AND rangeAjout -|- nom_prenom_validite AND nom_prenom_validite >> rangeAjout;
	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, nom_, prenom_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));
		
		
	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, nom_, prenom_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, nom_, prenom_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, nom_, prenom_, date_debut_, date_fin_);
		
	END IF;
	
	
	
	--Etudiant_contact--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT contact_validite INTO rangeAdjacentGauche FROM Etudiant_contact_Validite WHERE matricule = matricule_ AND courriel = courriel_ AND telephone = telephone_ AND rangeAjout -|- contact_validite AND contact_validite << rangeAjout;
	SELECT contact_validite INTO rangeAdjacentDroite FROM Etudiant_contact_Validite WHERE matricule = matricule_ AND courriel = courriel_ AND telephone = telephone_ AND rangeAjout -|- contact_validite AND contact_validite >> rangeAjout;
	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, courriel_, telephone_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));
		
		
	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, courriel_, telephone_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, courriel_, telephone_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, courriel_, telephone_, date_debut_, date_fin_);
		
	END IF;
			
			
			
	--Etudiant_adresseID--
	--Vérification s'il y a des tuples adjacents à gauche et à droite
	SELECT adresseID_validite INTO rangeAdjacentGauche FROM Etudiant_adresseID_Validite WHERE matricule = matricule_ AND adresseID = adresseID_ AND rangeAjout -|- adresseID_validite AND adresseID_validite << rangeAjout;
	SELECT adresseID_validite INTO rangeAdjacentDroite FROM Etudiant_adresseID_Validite WHERE matricule = matricule_ AND adresseID = adresseID_ AND rangeAjout -|- adresseID_validite AND adresseID_validite >> rangeAjout;
	
	--S'il est entouré
	IF (rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NOT NULL) THEN
		CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, adresseID_, lower(rangeAdjacentGauche), upper(rangeAdjacentDroite));
		
		
	--S'il y a seulement un tuple à gauche
	ELSIF ((rangeAdjacentGauche IS NOT NULL) AND (rangeAdjacentDroite IS NULL)) THEN
		CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rangeAdjacentGauche);
		CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, adresseID_, lower(rangeAdjacentGauche), date_fin_);
		
	--S'il y a seulement un tuple à droite
	ELSIF ((rangeAdjacentGauche IS NULL) AND (rangeAdjacentDroite IS NOT NULL)) THEN
		CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rangeAdjacentDroite);
		CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, adresseID_, date_debut_, upper(rangeAdjacentDroite));
	
	--Il n'y a aucun tuple qui sont adjacent
	ELSE	
		CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, adresseID_, date_debut_, date_fin_);
		
	END IF;
		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour toutes les tables de validité---------
--Si on modifie dans seulement une seule table, il se pourrait que certains attributs soient NULL pour certaine période, ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut modifier dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE etudiant_validite_modification(matricule_ Etudiant_Matricule,
														   prenom_ nom_prenom, 
														   nom_ nom_prenom, 
														   courriel_ email, 
														   telephone_ phoneNumber,
														   adresseID_ INT,
														   date_debut_ Estampille,
														   date_fin_ Estampille
														   )
															 
AS $$
DECLARE 

BEGIN	
	
	--Un update est l'équivalent d'effacer puis de ré-insérer
	call etudiant_validite_effacer(matricule_, date_debut_, date_fin_);
	call etudiant_validite_ajout(matricule_, prenom_, nom_, courriel_, telephone_, adresseID_, date_debut_, date_fin_);

END;
$$ LANGUAGE plpgsql;



--------Permet d'effacer dans toutes les tables de validité---------
--Si on efface dans seulement une seule table, il se pourrait que certains attributs soient NULL pour certaine période, ce qui n'est pas permis parce que les attributs ne peuvent pas être NULL
--Donc, il faut effacer dans toutes les tables pour la même période.
CREATE OR REPLACE PROCEDURE etudiant_validite_effacer(matricule_ Etudiant_Matricule,
													  date_effacement_debut_ Estampille,
													  date_effacement_fin_ Estampille
													  )
															 
AS $$
DECLARE 
	rangeEffacement TSRANGE_sec;
	rec RECORD;
BEGIN	
	IF (date_effacement_debut_ >= date_effacement_fin_) THEN
		RAISE EXCEPTION 'LA DATE DE FIN DOIT ETRE APRES LA DATE DE DEBUT';
		RETURN;
	END IF;
	
	
	rangeEffacement = TSRANGE_sec(date_effacement_debut_, date_effacement_fin_, '[)');
		
		
	--À faire pour toutes les tables de validitées
	
	--Si le nouveau range est contenu dans un autre tuple : On sépare l'ancien tuple entre avant et après; Situation unique
	--Ancien   : ==========
	--Effacer  :    ====
	--Résultat : ===    ===
	
	--Si des elements sont contenus dans le range : On les effaces; Peut arriver sur plusieurs tuples
	--Ancien 1 :     ====
	--Ancien 2 :		 =====
	--Effacer  :    ===========
	--Résultat :    	
	
	--S'il y a chevauchement & ne s'étend pas sur la droite : On modifie l'ancien tuple jusqu'au début de l'effacement; Situation unique
    --Ancien   : =======
	--Effacer  :      =====
	--Résultat : =====
	
	--S'il y a chevauchement & ne s'étend pas sur la gauche : On modifie l'ancien tuple jusqu'à la fin de l'effacement; Situation unique
    --Ancien   :    =======
	--Effacer  : =====
	--Résultat :      =====
	
	
	
	 	------Matricule_validité------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Etudiant_Matricule_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement <@ etudiant_validite
		LOOP
			CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rec.etudiant_validite);
			CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, lower(rec.etudiant_validite), date_effacement_debut_);
			CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, date_effacement_fin_, upper(rec.etudiant_validite));
		END LOOP;
		
		
		--Element contenu dans le range--
		FOR rec IN SELECT * 
				   FROM Etudiant_Matricule_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement @> etudiant_validite
		LOOP
			CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rec.etudiant_validite);			
		END LOOP;
		
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Etudiant_Matricule_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && etudiant_validite AND etudiant_validite &< rangeEffacement
		LOOP
			CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rec.etudiant_validite);
			CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, lower(rec.etudiant_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Etudiant_Matricule_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && etudiant_validite AND etudiant_validite &> rangeEffacement
		LOOP
			CALL etudiant_matricule_validite_effacer_PRIVATE(matricule_, rec.etudiant_validite);
			CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, date_effacement_fin_, upper(rec.etudiant_validite));
		END LOOP;
		
		
		------Nom_prenom_validité------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Etudiant_nom_prenom_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement <@ nom_prenom_validite
		LOOP
			CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rec.nom_prenom_validite);
			CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, rec.nom, rec.prenom, lower(rec.nom_prenom_validite), date_effacement_debut_);
			CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, rec.nom, rec.prenom, date_effacement_fin_, upper(rec.nom_prenom_validite));
		END LOOP;
		
		--Element contenu dans le range--
				FOR rec IN SELECT * 
				   FROM Etudiant_nom_prenom_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement @> nom_prenom_validite
		LOOP
			CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rec.nom_prenom_validite);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Etudiant_nom_prenom_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && nom_prenom_validite AND nom_prenom_validite &< rangeEffacement
		LOOP
			CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rec.nom_prenom_validite);
			CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, rec.nom, rec.prenom, lower(rec.nom_prenom_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Etudiant_nom_prenom_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && nom_prenom_validite AND nom_prenom_validite &> rangeEffacement
		LOOP
			CALL etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_, rec.nom_prenom_validite);
			CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_, rec.nom, rec.prenom, date_effacement_fin_, upper(rec.nom_prenom_validite));
		END LOOP;
		
		
		------contact_validité------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Etudiant_contact_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement <@ contact_validite
		LOOP
			CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rec.contact_validite);
			CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, rec.courriel, rec.telephone, lower(rec.contact_validite), date_effacement_debut_);
			CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, rec.courriel, rec.telephone, date_effacement_fin_, upper(rec.contact_validite));
		END LOOP;
			
		--Element contenu dans le range--
		FOR rec IN SELECT * 
				   FROM Etudiant_contact_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement @> contact_validite
		LOOP
			CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rec.contact_validite);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Etudiant_contact_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && contact_validite AND contact_validite &< rangeEffacement
		LOOP
			CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rec.contact_validite);
			CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, rec.courriel, rec.telephone, lower(rec.contact_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Etudiant_contact_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && contact_validite AND contact_validite &> rangeEffacement
		LOOP
			CALL etudiant_contact_validite_effacer_PRIVATE(matricule_, rec.contact_validite);
			CALL etudiant_contact_validite_ajout_PRIVATE(matricule_, rec.courriel, rec.telephone, date_effacement_fin_, upper(rec.contact_validite));
		END LOOP;
		
		
		
		------adresseID_validité------
		--Contenu dans un autre tuple--
		FOR rec IN SELECT * 
				   FROM Etudiant_adresseID_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement <@ adresseID_validite
		LOOP
			CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rec.adresseID_validite);
			CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, rec.adresseID, lower(rec.adresseID_validite), date_effacement_debut_);
			CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, rec.adresseID, date_effacement_fin_, upper(rec.adresseID_validite));
		END LOOP;

		--Element contenu dans le range--
		FOR rec IN SELECT * 
				   FROM Etudiant_adresseID_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement @> adresseID_validite
		LOOP
			CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rec.adresseID_validite);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la droite--
		FOR rec IN SELECT * 
				   FROM Etudiant_adresseID_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && adresseID_validite AND adresseID_validite &< rangeEffacement
		LOOP
			CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rec.adresseID_validite);
			CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, rec.adresseID, lower(rec.adresseID_validite), date_effacement_debut_);
		END LOOP;
		
		
		--Chevauchement et ne s'étend pas sur la gauche
		FOR rec IN SELECT * 
				   FROM Etudiant_adresseID_Validite 
				   WHERE matricule = matricule_ AND rangeEffacement && adresseID_validite AND adresseID_validite &> rangeEffacement
		LOOP
			CALL etudiant_adresseID_validite_effacer_PRIVATE(matricule_, rec.adresseID_validite);
			CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_, rec.adresseID, date_effacement_fin_, upper(rec.adresseID_validite));
		END LOOP;
		
		
		
END;
$$ LANGUAGE plpgsql;



--------Permet d'ajouter dans la table Etudiant_matricule--------
CREATE OR REPLACE PROCEDURE etudiant_matricule_validite_ajout_PRIVATE(matricule Etudiant_Matricule,
															          date_debut Estampille,
															  		  date_fin Estampille
															          )
															 
AS $$
BEGIN	

	INSERT INTO Etudiant_matricule_validite(matricule,
											etudiant_validite
										   )
		VALUES (
			matricule,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;

--------Permet de mettre à jour un tuple dans la table Etudiant_matricule--------
CREATE OR REPLACE PROCEDURE etudiant_matricule_validite_modification_PRIVATE(matricule_ Etudiant_Matricule,
															                 range_date_initiale TSRANGE_sec,
																		     date_debut_nouveau Estampille,
																	         date_fin_nouveau Estampille
															                )
															 
AS $$
BEGIN	

	UPDATE Etudiant_matricule_validite
	SET etudiant_validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE matricule = matricule_ AND
	      etudiant_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Etudiant_matricule--------
CREATE OR REPLACE PROCEDURE etudiant_matricule_validite_effacer_PRIVATE(matricule_ Etudiant_Matricule,
															            range_date TSRANGE_sec
															            )
															 
AS $$
BEGIN	

	DELETE FROM Etudiant_matricule_validite
	WHERE matricule = matricule_ AND
	      etudiant_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;


--------Permet d'ajouter dans la table Etudiant_nom_prenom--------
CREATE OR REPLACE PROCEDURE etudiant_nom_prenom_validite_ajout_PRIVATE(matricule Etudiant_Matricule,
															           nom nom_prenom,
															           prenom nom_prenom,
															           date_debut Estampille,
															           date_fin Estampille
															          )
															 
AS $$
BEGIN	

	INSERT INTO Etudiant_nom_prenom_validite(matricule,
											 nom,
											 prenom,
											 nom_prenom_validite
										    )
		VALUES (
			matricule,
			nom,
			prenom,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour un tuple dans la table Etudiant_nom_prenom--------
CREATE OR REPLACE PROCEDURE etudiant_nom_prenom_validite_modification_PRIVATE(matricule_ Etudiant_Matricule,
															                  range_date_initiale TSRANGE_sec,
																			  nom_nouveau nom_prenom,
																			  prenom_nouveau nom_prenom,
																		      date_debut_nouveau Estampille,
																	          date_fin_nouveau Estampille
															                 )
															 
AS $$
BEGIN	

	UPDATE Etudiant_nom_prenom_validite
	SET nom = nom_nouveau,
		prenom = prenom_nouveau,
	    nom_prenom_validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE matricule = matricule_ AND
	      nom_prenom_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Etudiant_nom_prenom--------
CREATE OR REPLACE PROCEDURE etudiant_nom_prenom_validite_effacer_PRIVATE(matricule_ Etudiant_Matricule,
															             range_date TSRANGE_sec
															             )
															 
AS $$
BEGIN	

	DELETE FROM Etudiant_nom_prenom_validite
	WHERE matricule = matricule_ AND
	      nom_prenom_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'ajouter dans la table de Etudiant_contact--------
CREATE OR REPLACE PROCEDURE etudiant_contact_validite_ajout_PRIVATE(matricule Etudiant_Matricule,
															        courriel email,
															        telephone phoneNumber,
															        date_debut Estampille,
															        date_fin Estampille
														        	)
															 
AS $$
BEGIN	

	INSERT INTO Etudiant_contact_validite(matricule,
											 courriel,
											 telephone,
											 contact_validite
										    )
		VALUES (
			matricule,
			courriel,
			telephone,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour un tuple dans la table Etudiant_contact--------
CREATE OR REPLACE PROCEDURE etudiant_contact_validite_modification_PRIVATE(matricule_ Etudiant_Matricule,
															               range_date_initiale TSRANGE_sec,
																		   courriel_nouveau email,
																		   telephone_nouveau phoneNumber,
																		   date_debut_nouveau Estampille,
																	       date_fin_nouveau Estampille
															               )
															 
AS $$
BEGIN	

	UPDATE Etudiant_contact_validite
	SET courriel = courriel_nouveau,
		telephone = telephone_nouveau,
	    contact_validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE matricule = matricule_ AND
	      contact_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Etudiant_contact--------
CREATE OR REPLACE PROCEDURE etudiant_contact_validite_effacer_PRIVATE(matricule_ Etudiant_Matricule,
															          range_date TSRANGE_sec
															          )
															 
AS $$
BEGIN	

	DELETE FROM Etudiant_contact_validite
	WHERE matricule = matricule_ AND
	      contact_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;


--------Permet d'ajouter dans la table Etudiant_adresseID--------
CREATE OR REPLACE PROCEDURE etudiant_adresseID_validite_ajout_PRIVATE(matricule Etudiant_Matricule,
															          adresseID INT,
															          date_debut Estampille,
															          date_fin Estampille
															          )
															 
AS $$
BEGIN	

	INSERT INTO Etudiant_adresseID_validite(matricule,
										  adresseID,
										  adresseID_validite
										  )
		VALUES (
			matricule,
			adresseID,
			TSRANGE_sec(date_debut, date_fin, '[)')
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet de mettre à jour un tuple dans la table Etudiant_adresseID--------
CREATE OR REPLACE PROCEDURE etudiant_adresseID_validite_modification_PRIVATE(matricule_ Etudiant_Matricule,
															                  range_date_initiale TSRANGE_sec,
																			  adresseID_nouveau INT,
																		      date_debut_nouveau Estampille,
																	          date_fin_nouveau Estampille
															                 )
															 
AS $$
BEGIN	

	UPDATE Etudiant_adresseID_validite
	SET adresseID = adresseID_nouveau,
	    adresseID_validite = TSRANGE_sec(date_debut_nouveau, date_fin_nouveau, '[)')
	WHERE matricule = matricule_ AND
	      adresseID_validite = range_date_initiale;
		
END;
$$ LANGUAGE plpgsql;

--------Permet d'effacer un tuple dans la table Etudiant_adresseID--------
CREATE OR REPLACE PROCEDURE etudiant_adresseID_validite_effacer_PRIVATE(matricule_ Etudiant_Matricule,
															            range_date TSRANGE_sec
															            )
															 
AS $$
BEGIN	

	DELETE FROM Etudiant_adresseID_validite
	WHERE matricule = matricule_ AND
	      adresseID_validite = range_date;
		
END;
$$ LANGUAGE plpgsql;




-------------------------------------------------------
--------Permet d'ajouter dans la table courante--------
--------Permet d'ajouter à un moment précis--------
CREATE OR REPLACE PROCEDURE etudiant_courante_ajout_at(matricule_ Etudiant_Matricule,
													  prenom_ nom_prenom, 
													  nom_ nom_prenom, 
													  courriel_ email, 
													  telephone_ phoneNumber,
													  adresseID_ INT,
													  date_ajout_ Estampille
													  )
AS $$
BEGIN	

	--On vérifie que la date d'ajout est plus grande que les dates pour la même clé dans les tables de validité
	--On ne peut pas ajouter un tuple valide qui est plus vieux qu'un tuple fermé
	--TO DO
	
	INSERT INTO Etudiant_Courante(matricule,
								  matricule_since, 
								  prenom,
								  nom,
								  nom_prenom_since,
								  courriel, 
								  telephone,
								  contact_since,
								  adresseID,
								  adresseID_since
								  )
		VALUES (
			matricule_,
			date_ajout_,
			prenom_,
			nom_,
			date_ajout_,
			courriel_,
			telephone_,
			date_ajout_,
			adresseID_,
			date_ajout_
		);
		
END;
$$ LANGUAGE plpgsql;


--------Permet d'ajouter maintenant--------
CREATE OR REPLACE PROCEDURE etudiant_courante_ajout_now(matricule_ Etudiant_Matricule,
													  	prenom_ nom_prenom, 
													  	nom_ nom_prenom, 
													  	courriel_ email, 
													  	telephone_	phoneNumber,
													  	adresseID_ INT
													  	)
AS $$
BEGIN	
	
	CALL etudiant_courante_ajout_at(matricule_, 
									prenom_, 
									nom_, 
									courriel_, 
									telephone_, 
									adresseID_, 
									NOW()::Estampille);

END;
$$ LANGUAGE plpgsql;



--Permet de modifier le nom ou le prénom dans la table courante--
--Permet de modifier à un moment précis
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_nom_prenom_at(matricule_ Etudiant_Matricule,
													  				 prenom_ nom_prenom, 
													  				 nom_ nom_prenom, 
													  				 date_changement Estampille
													  	            )
AS $$
DECLARE
	prenom_avant nom_prenom;
	nom_avant nom_prenom;
	nom_prenom_since_avant Estampille;
BEGIN	
	
	--La date de retrait ne peut qu'être après la date initiale
	SELECT prenom, nom, nom_prenom_since INTO prenom_avant, nom_avant, nom_prenom_since_avant 
	FROM etudiant_courante WHERE matricule = matricule_;
	
	IF (nom_prenom_since_avant >= date_changement) THEN
		RAISE EXCEPTION 'LA DATE DOIT ETRE APRES LA DATE COURANTE';
		RETURN;
	END IF;
	
	--Sauvegarde de l'ancienne valeur dans la table de validité
	CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_,
											        nom_avant,
											        prenom_avant,
											        nom_prenom_since_avant,
											        date_changement);
													
	--Modification dans la table courante
	UPDATE Etudiant_Courante SET prenom = prenom_, nom = nom_, nom_prenom_since = date_changement  WHERE matricule = matricule_;
	
END;
$$ LANGUAGE plpgsql;


--Permet de modifier maintenant
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_nom_prenom_now(matricule_ Etudiant_Matricule,
													  				  prenom_ nom_prenom, 
													  				  nom_ nom_prenom 
													  	             )
AS $$
BEGIN	
	
	CALL etudiant_courante_modifier_nom_prenom_at(matricule_,
												  prenom_, 
												  nom_, 
												  NOW()::Estampille
												  );
	
END;
$$ LANGUAGE plpgsql;




--Permet de modifier les informations de contact dans la table courante--
--Permet de modifier à un moment précis
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_contact_at(matricule_ Etudiant_Matricule,
													  			  courriel_ email, 
													  			  telephone_ phoneNumber, 
													  			  date_changement Estampille
													  	          )
AS $$
DECLARE
	courriel_avant email;
	telephone_avant phoneNumber;
	contact_since_avant Estampille;
BEGIN	
	
	--La date de retrait ne peut qu'être après la date initiale
	SELECT courriel, telephone, contact_since INTO courriel_avant, telephone_avant, contact_since_avant 
	FROM etudiant_courante WHERE matricule = matricule_;
	
	IF (contact_since_avant >= date_changement) THEN
		RAISE EXCEPTION 'LA DATE DOIT ETRE APRES LA DATE COURANTE';
		RETURN;
	END IF;
	
	--Sauvegarde de l'ancienne valeur dans la table de validité
	CALL etudiant_contact_validite_ajout_PRIVATE(matricule_,
											     courriel_avant,
											     telephone_avant,
											     contact_since_avant,
											     date_changement);
													
	--Modification dans la table courante
	UPDATE Etudiant_Courante SET courriel = courriel_, telephone = telephone_, contact_since = date_changement  WHERE matricule = matricule_;
	
END;
$$ LANGUAGE plpgsql;


--Permet de modifier maintenant
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_contact_now(matricule_ Etudiant_Matricule,
													  			   courriel_ email, 
													  			   telephone_ phoneNumber
													  	           )
AS $$
BEGIN	
	
	CALL etudiant_courante_modifier_contact_at(matricule_,
											   courriel_, 
											   telephone_, 
											   NOW()::Estampille
											   );
	
END;
$$ LANGUAGE plpgsql;


--Permet de modifier l'adresseID dans la table courante--
--Permet de modifier à un moment précis
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_adresseID_at(matricule_ Etudiant_Matricule,
													  			    adresseID_ INT, 
													  			    date_changement Estampille
													  	            )
AS $$
DECLARE
	adresseID_avant INT;
	adresseID_since_avant Estampille;
BEGIN	
	
	--La date de retrait ne peut qu'être après la date initiale
	SELECT adresseID, adresseID_since INTO adresseID_avant, adresseID_since_avant FROM etudiant_courante WHERE matricule = matricule_;
	
	IF (adresseID_since_avant >= date_changement) THEN
		RAISE EXCEPTION 'LA DATE DOIT ETRE APRES LA DATE COURANTE';
		RETURN;
	END IF;
	
	--Sauvegarde de l'ancienne valeur dans la table de validité
	CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_,
											       adresseID_avant,
											       adresseID_since_avant,
											       date_changement);
													
	--Modification dans la table courante
	UPDATE Etudiant_Courante SET adresseID = adresseID_, adresseID_since = date_changement  WHERE matricule = matricule_;
	
END;
$$ LANGUAGE plpgsql;


--Permet de modifier maintenant
CREATE OR REPLACE PROCEDURE etudiant_courante_modifier_adresseID_now(matricule_ Etudiant_Matricule,
													  			     adresseID_ INT
													  	             )
AS $$
BEGIN	
	
	CALL etudiant_courante_modifier_adresseID_at(matricule_,
											   adresseID_, 
											   NOW()::Estampille
											   );
	
END;
$$ LANGUAGE plpgsql;

--Permet d'effacer de la table courante
--Permet d'effacer à un moment précis
CREATE OR REPLACE PROCEDURE etudiant_courante_retrait_at(matricule_ Etudiant_Matricule,
													  	 date_retrait_ Estampille
													    )
AS $$
DECLARE
	matricule_since_ Estampille;
	
	prenom_ nom_prenom;
	nom_ nom_prenom;
	nom_prenom_since_ Estampille; 

	courriel_ email;	
	telephone_ phoneNumber;
	contact_since_ Estampille;
	
	adresseID_ INT;
	adresseID_since_ Estampille;

BEGIN	
	
	
	SELECT matricule_since,  
		   prenom,
		   nom,
		   nom_prenom_since,
		   courriel,
		   telephone,
		   contact_since,
		   adresseID,
		   adresseID_since
		   
	INTO matricule_since_,
	     prenom_,
		 nom_,
		 nom_prenom_since_,
		 courriel_,
		 telephone_,
		 contact_since_,
		 adresseID_,
		 adresseID_since_
		 
	FROM etudiant_courante WHERE matricule = matricule_;
	
	--La date de retrait ne peut qu'être après les dates d'ajout
	IF (GREATEST(matricule_since_, nom_prenom_since_, contact_since_, adresseID_since_) >= date_retrait_) THEN
		RAISE EXCEPTION 'LA DATE D EFFACEMENT DOIT ETRE APRES LES DATES D AJOUT';
		RETURN;
	END IF;
	
	--Sauvegarde des données dans les tables de validitées
	--Sauvegarde du matricule	
	CALL etudiant_matricule_validite_ajout_PRIVATE(matricule_, 
										           matricule_since_, 
										           date_retrait_);
	
	--Sauvegarde du nom et prénom
	CALL etudiant_nom_prenom_validite_ajout_PRIVATE(matricule_,
											        nom_,
											        prenom_,
											        nom_prenom_since_,
											        date_retrait_);

	--Sauvegarde des informations de contact
	CALL etudiant_contact_validite_ajout_PRIVATE(matricule_,
										         courriel_,
										         telephone_,
										         contact_since_,
										         date_retrait_);
										 
	--Sauvegarde de l'adresse
	CALL etudiant_adresseID_validite_ajout_PRIVATE(matricule_,
										           adresseID_,
										           adresseID_since_,
										           date_retrait_);

	--On efface la ligne dans la table courante
	DELETE FROM Etudiant_Courante WHERE matricule = matricule_;
	
END;
$$ LANGUAGE plpgsql;

--Permet d'effacer maintenant
CREATE OR REPLACE PROCEDURE etudiant_courante_retrait_now(matricule_ Etudiant_Matricule)
AS $$

BEGIN	
	CALL etudiant_courante_retrait_at(matricule_, 
									  NOW()::Estampille);
	
END;
$$ LANGUAGE plpgsql;



-------API------
-- Adresse table courante
--Insertion
CREATE OR REPLACE PROCEDURE Adresse_Courante_ins(
  adresseID_ INT,
	appartement_ Adresse_Appartement,
	rue_ Adresse_Rue,
	ville_ Adresse_Ville,
	region_ Adresse_Region,
	code_postal_ Adresse_CP,
	pays_ Adresse_Pays,
	date_ajout_ Estampille
	)
AS $$
BEGIN
  CALL Adresse_Courante_ajout_at(
      	adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_,
	    date_ajout_
      );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE Adresse_Courante_now_ins(
  adresseID_ INT,
	appartement_ Adresse_Appartement,
	rue_ Adresse_Rue,
	ville_ Adresse_Ville,
	region_ Adresse_Region,
	code_postal_ Adresse_CP,
	pays_ Adresse_Pays
	)
AS $$
BEGIN
  CALL Adresse_Courante_ajout_now(
      adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_
      );
END;
$$ LANGUAGE plpgsql;

--Modification
CREATE OR REPLACE PROCEDURE Adresse_Courante_Localisation_mod(
  adresseID_ INT,
	appartement_ Adresse_Appartement,
	rue_ Adresse_Rue,
	ville_ Adresse_Ville,
	region_ Adresse_Region,
	code_postal_ Adresse_CP,
	pays_ Adresse_Pays,
	date_changement Estampille
	)
AS $$
BEGIN
  CALL Adresse_Courante_modifier_Localisation_at(
      adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_,
      date_changement
      );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE Adresse_Courante_Localisation_now_mod(
  adresseID_ INT,
	appartement_ Adresse_Appartement,
	rue_ Adresse_Rue,
	ville_ Adresse_Ville,
	region_ Adresse_Region,
	code_postal_ Adresse_CP,
	pays_ Adresse_Pays
	)
AS $$
BEGIN
  CALL Adresse_Courante_modifier_Localisation_now(
      adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_
      );
END;
$$ LANGUAGE plpgsql;

--Retrait
CREATE OR REPLACE PROCEDURE Adresse_Courante_ret(
  adresseID_ INT,
	date_retrait_ Estampille
	)
AS $$
BEGIN
  CALL Adresse_Courante_retrait_at(
      adresseID_,
	    date_retrait_
      );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE Adresse_Courante_now_ret(
  adresseID_ INT
	)
AS $$
BEGIN
  CALL Adresse_Courante_retrait_now(
      adresseID_
      );
END;
$$ LANGUAGE plpgsql;


-- Adresse table validite
--Insertion
CREATE OR REPLACE PROCEDURE adresse_validite_ins(
    adresseID_ INT,
	  appartement_ Adresse_Appartement,
	  rue_ Adresse_Rue,
	  ville_ Adresse_Ville,
	  region_ Adresse_Region,
	  code_postal_ Adresse_CP,
	  pays_ Adresse_Pays,
	  date_debut_ Estampille,
	  date_fin_ Estampille
)
AS $$
BEGIN
  CALL adresse_validite_ajout(
      adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_,
	    date_debut_,
	    date_fin_
      );
END;
$$ LANGUAGE plpgsql;



-- Modification
CREATE OR REPLACE PROCEDURE adresse_validite_mod(
    adresseID_ INT,
	  appartement_ Adresse_Appartement,
	  rue_ Adresse_Rue,
	  ville_ Adresse_Ville,
	  region_ Adresse_Region,
	  code_postal_ Adresse_CP,
	  pays_ Adresse_Pays,
	  date_debut_ Estampille,
	  date_fin_ Estampille
  )
AS $$
BEGIN
  CALL adresse_validite_modification(
      adresseID_,
	    appartement_,
	    rue_,
	    ville_,
	    region_,
	    code_postal_,
	    pays_,
	    date_debut_,
	    date_fin_
      );
END;
$$ LANGUAGE plpgsql;


-- Retrait
CREATE OR REPLACE PROCEDURE adresse_validite_ret(
  adresseID_ INT,
	date_effacement_debut_ Estampille,
	date_effacement_fin_ Estampille
	)
AS $$
BEGIN
  CALL adresse_validite_effacer(
      adresseID_,
	    date_effacement_debut_,
	    date_effacement_fin_
      );
END;
$$ LANGUAGE plpgsql;



-- Etudiant table courante
--Insertion
CREATE OR REPLACE PROCEDURE etudiant_courant_ins(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom, 
	courriel_ email, 
	telephone_ phoneNumber,
	adresseID_ INT,
	date_ajout_ Estampille
	)
AS $$
BEGIN
  CALL etudiant_courante_ajout_at(
    	matricule_,
		prenom_, 
		nom_, 
		courriel_, 
		telephone_,
		adresseID_,
		date_ajout_
    	);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE etudiant_courant_now_ins(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom, 
	courriel_ email, 
	telephone_ phoneNumber,
	adresseID_ INT
	)
AS $$
BEGIN
  CALL etudiant_courante_ajout_now(
    	matricule_,
		prenom_, 
		nom_, 
		courriel_, 
		telephone_,
		adresseID_
    	);
END;
$$ LANGUAGE plpgsql;


--Modification
CREATE OR REPLACE PROCEDURE etudiant_courant_nom_prenom_mod(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom, 
	date_changement Estampille
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_nom_prenom_at(
    	matricule_,
		prenom_, 
		nom_, 
		date_changement
    	);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE etudiant_courant_nom_prenom_now_mod(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_nom_prenom_now(
    	matricule_,
		prenom_, 
		nom_
    	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE etudiant_courant_contact_mod(
	matricule_ Etudiant_Matricule,
	courriel_ email, 
	telephone_ phoneNumber, 
	date_changement Estampille
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_contact_at(
    	matricule_,
		courriel_, 
		telephone_, 
		date_changement
    	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE etudiant_courant_contact_now_mod(
	matricule_ Etudiant_Matricule,
	courriel_ email, 
	telephone_ phoneNumber
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_contact_now(
    	matricule_,
		courriel_, 
		telephone_
    	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE etudiant_courant_adresseID_mod(
	matricule_ Etudiant_Matricule,
	adresseID_ INT, 
	date_changement Estampille
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_adresseID_at(
    	matricule_,
		adresseID_, 
		date_changement
    	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE etudiant_courant_adresseID_now_mod(
	matricule_ Etudiant_Matricule,
	adresseID_ INT
	)
AS $$
BEGIN
  CALL etudiant_courante_modifier_adresseID_now(
    	matricule_,
		adresseID_
    	);
END;
$$ LANGUAGE plpgsql;

-- Retrait
CREATE OR REPLACE PROCEDURE etudiant_courant_ret(
	matricule_ Etudiant_Matricule,
	date_retrait_ Estampille
	)
AS $$
BEGIN
  CALL etudiant_courante_retrait_at(
    	matricule_,
		date_retrait_
    	);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE etudiant_courant_now_ret(
	matricule_ Etudiant_Matricule
	)
AS $$
BEGIN
  CALL etudiant_courante_retrait_now(
    	matricule_
    	);
END;
$$ LANGUAGE plpgsql;

-- Etudiant table validite
--Insertion
CREATE OR REPLACE PROCEDURE etudiant_validite_ins(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom, 
	courriel_ email, 
	telephone_ phoneNumber,
	adresseID_ INT,
	date_debut_ Estampille,
	date_fin_ Estampille
	)
AS $$
BEGIN
  CALL etudiant_validite_ajout(
    	matricule_,
		prenom_, 
		nom_, 
		courriel_, 
		telephone_,
		adresseID_,
		date_debut_,
		date_fin_
    	);
END;
$$ LANGUAGE plpgsql;


--Modification
CREATE OR REPLACE PROCEDURE etudiant_validite_mod(
	matricule_ Etudiant_Matricule,
	prenom_ nom_prenom, 
	nom_ nom_prenom, 
	courriel_ email, 
	telephone_ phoneNumber,
	adresseID_ INT,
	date_debut_ Estampille,
	date_fin_ Estampille
	)
AS $$
BEGIN
  CALL etudiant_validite_modification(
    	matricule_,
		prenom_, 
		nom_, 
		courriel_, 
		telephone_,
		adresseID_,
		date_debut_,
		date_fin_
    	);
END;
$$ LANGUAGE plpgsql;

-- Retrait
CREATE OR REPLACE PROCEDURE etudiant_validite_ret(
	matricule_ Etudiant_Matricule,
	date_effacement_debut_ Estampille,
	date_effacement_fin_ Estampille
	)
AS $$
BEGIN
  CALL etudiant_validite_effacer(
    	matricule_,
		date_effacement_debut_,
		date_effacement_fin_
    	);
END;
$$ LANGUAGE plpgsql;


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

