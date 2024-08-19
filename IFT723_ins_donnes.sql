/*
-- ===========================================================================
-- IFT723_ins_donnes.sql
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
Résumé : Insertion des données de test pour les tables du schéma IFT723.
-- ===========================================================================
*/


-- Localisation du schéma
set schema 'IFT723';

-- Insertion de données dans la table courante de Adresse
CALL Adresse_Courante_ins(1, '5', '3996 rue Levy', 'Montréal', 'Quebec',  'H3C 5K4', 'Canada', '2021-3-22 8:46:21');
CALL Adresse_Courante_ins(2, NULL, '4873 Fallon Drive', 'Port Lambton', 'Ontario',  'N0P 2B0', 'Canada', '2017-3-21 2:24:11');
CALL Adresse_Courante_ins(3, '404', '4904 Brand Road', 'Saskatoon', 'Saskatchewan',  'S7K 1W8', 'Canada', '2023-8-23 13:12:24');
CALL Adresse_Courante_ins(4, '15', '2031 40th Street', 'Edmonton', 'Alberta',  'T2P 3Z3', 'Canada', '2019-1-3 5:6:4');
CALL Adresse_Courante_ins(5, NULL, '4282 boulevard des Laurentides', 'St Sylvere', 'Quebec',  'G9Z 1H0', 'Canada', '2023-1-3 5:6:4');
CALL Adresse_Courante_now_ins(6, NULL, '879 Burdett Avenue', 'Victoria', 'British Columbia',  'V8W 1B2', 'Canada');
CALL Adresse_Courante_now_ins(7, '2', '3269 Glen Long Avenue', 'Toronto', 'Ontario',  'M6B 1J8', 'Canada');
CALL Adresse_Courante_now_ins(8, '9', '96 White Point Road', 'Shelburne', 'Nova Scotia',  'B0T 1W0', 'Canada');
CALL Adresse_Courante_now_ins(9, NULL, '1064 Kinchant St', 'Williams Lake', 'British Columbia',  'V2G 1H9', 'Canada');
CALL Adresse_Courante_now_ins(10, '1', '975 Toy Avenue', 'Oshawa', 'Ontario',  'L1H 7M3', 'Canada');


-- Insertion de données dans les tables de validité de Adresse
CALL adresse_validite_ins(11, '50', '1459 Thurston Dr', 'Orleans', 'Ontario',  'K1C 1T1', 'Canada', '2021-2-13 17:25:21', '2023-11-17 8:59:40');
CALL adresse_validite_ins(12, '13', '939 Blind Bay Road', 'Clearwater', 'British Columbia',  'V0E 1N0', 'Canada', '2015-2-5 5:51:39', '2021-2-17 4:52:39');
CALL adresse_validite_ins(13, NULL, '4665 White Point Road', 'Lahave', 'Nova Scotia',  'B0R 1C0', 'Canada', '2018-11-23 8:37:47', '2023-3-2 13:1:37');
CALL adresse_validite_ins(14, '2', '3425 Brand Road', 'Saskatoon', 'Saskatchewan',  'S7K 1W8', 'Canada', '2015-7-11 3:26:49', '2020-9-21 8:26:33');
CALL adresse_validite_ins(15, '1', '4067 Riedel Street', 'Fort Mcmurray', 'Alberta',  'T9H 3J9', 'Canada', '2019-6-4 23:53:5', '2022-4-27 21:43:2');


-- Insertion de données dans la table courante de Etudiant
CALL etudiant_courant_ins('0000000001', 'Nancy', 'F. Shaw', 'NancyFShaw@dayrep.com', '7804473856', 1, '2023-12-15 19:41:46');
CALL etudiant_courant_ins('0000000002', 'Michael', 'M. Harmon', 'MichaelMHarmon@armyspy.com', '5146172250', 2, '2019-2-1 5:55:11');
CALL etudiant_courant_ins('0000000003', 'Michael', 'B. McClure', 'MichaelBMcClure@armyspy.com', '4168331461', 3, '2016-12-15 14:49:60');
CALL etudiant_courant_ins('0000000004', 'Édouard', 'Bellemare', 'EdouardBellemare@jourrapide.com', '0282182322', 4, '2019-10-14 4:22:31');
CALL etudiant_courant_ins('0000000005', 'Jeoffroi', 'Léveillé', 'JeoffroiLeveille@teleworm.us', '7055445493', 5, '2022-3-12 5:38:8');
CALL etudiant_courant_now_ins('0000000006', 'Jesse', 'M. Green', 'JesseMGreen@dayrep.com', '8074863734', 6);
CALL etudiant_courant_now_ins('0000000007', 'Peverell', 'Paquin', 'PeverellPaquin@dayrep.com', '6043137800', 7);
CALL etudiant_courant_now_ins('0000000008', 'Ranger', 'Favreau', 'RangerFavreau@armyspy.com', '9054339242', 8);
CALL etudiant_courant_now_ins('0000000009', 'Jose', 'R. Doyle', 'JoseRDoyle@dayrep.com', '4163660812', 9);
CALL etudiant_courant_now_ins('0000000010', 'max2', 'S', 'max2S@test.ca', '3334445555', 10);



-- Insertion de données dans les tables de validité de Etudiant
CALL etudiant_validite_ins('0000000011', 'Eric', 'J. Reed', 'EricJReed@armyspy.com', '2503179297', 11, '2016-4-10 20:45:57','2018-7-25 19:51:51');
CALL etudiant_validite_ins('0000000012', 'Arnaud', 'Quirion', 'ArnaudQuirion@teleworm.us', '7052328136', 12, '2015-6-12 22:54:57','2022-1-26 9:44:52');
CALL etudiant_validite_ins('0000000013', 'Geoffrey', 'Pinneau', 'GeoffreyPinneau@armyspy.com', '9058151285', 13, '2016-6-22 14:46:30','2016-12-26 8:11:44');
CALL etudiant_validite_ins('0000000014', 'Phillip', 'R. Hartman', 'PhillipRHartman@rhyta.com', '4037732496', 14, '2022-3-21 19:13:1','2023-7-17 21:16:40');
CALL etudiant_validite_ins('0000000015', 'Clarence', 'S. Caruthers', 'ClarenceSCaruthers@jourrapide.com', '8675876066', 15, '2015-5-8 2:3:9','2016-10-23 14:38:4');

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


