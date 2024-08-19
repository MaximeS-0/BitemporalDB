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