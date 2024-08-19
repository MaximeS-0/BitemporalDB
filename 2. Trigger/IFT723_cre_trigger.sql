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
Résumé : Création des triggers de la base de données.
-- ===========================================================================
*/

SET SCHEMA 'IFT723';

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
