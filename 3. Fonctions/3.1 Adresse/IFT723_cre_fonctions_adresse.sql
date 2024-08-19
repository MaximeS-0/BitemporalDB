/*
-- ===========================================================================
-- IFT723_cre_fonctions.sql
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
Résumé : Création des fonctions de la base de données.
-- ===========================================================================
*/


SET SCHEMA 'IFT723';

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