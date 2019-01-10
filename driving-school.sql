/**********************/
/* LANDSCHOOT Ludovic */
/* COILLIAUX Thibault */
/************************ Création des tables ************************/
Create table ELEVE (
  e_id number(3) constraint eleve_pkey primary key,
  e_nom varchar2(10) not null,
  e_prenom varchar2(10) not null,
  e_date_naiss Date not null,
  e_tel varchar(2) not null,
  e_date_dossier Date not null,
  e_date_code Date
);

CREATE SEQUENCE sequence_id_eleve START WITH 1 INCREMENT BY 1;

Create table TRAJET (
  t_id number(3) constraint trajet_pkey primary key,
  e_id number(3) constraint trajet_eleve_fkey references ELEVE,
  t_date Date not null,
  t_nb_km number(5,1),
  t_type varchar2(9),
  constraint t_type_enum check(t_type in ('route','ville','autoroute'))
);

CREATE SEQUENCE sequence_id_trajet START WITH 1 INCREMENT BY 1;

Create table INSCRIPTION (
  i_id number(3) constraint inscription_pkey primary key,
  e_id number(3) constraint inscription_eleve_fkey references ELEVE,
  i_date_inscr Date,
  i_type varchar2(9),
  constraint i_type_enum check(i_type in ('classique','supervise','anticipe')),
  i_date_examen Date,
  i_resultat number(2),
  constraint i_resultat_check check (i_resultat>0),
  i_num number(2) default 1 not null
);

CREATE SEQUENCE sequence_id_inscription START WITH 1 INCREMENT BY 1;

Create table MONITEUR (
  m_id number(3) constraint moniteur_pkey primary key,
  m_nom varchar2(10) not null,
  m_prenom varchar2(10) not null
);

CREATE SEQUENCE sequence_id_moniteur START WITH 1 INCREMENT BY 1;

Create table LECON (
  l_id number(3) constraint lecon_pkey primary key,
  e_id number(3) constraint lecon_eleve_fkey references ELEVE,
  m_id number(3) constraint lecon_moniteur_fkey references MONITEUR,
  l_date Date not null,
  l_duree number(4) not null,
  constraint l_duree_check check(l_duree>0)
);

CREATE SEQUENCE sequence_id_lecon START WITH 1 INCREMENT BY 1;

/************************ SHOW TABLE ************************/
SELECT * FROM ELEVE;
SELECT * FROM TRAJET;
SELECT * FROM INSCRIPTION;
SELECT * FROM MONITEUR;
SELECT * FROM LECON;

/************************ Triggers ELEVE ************************/
CREATE OR REPLACE TRIGGER before_insert_update_eleve 
BEFORE INSERT OR UPDATE
ON ELEVE FOR EACH ROW
BEGIN 
	/* Nom et prénom toujours en majuscule */
	:new.e_nom := upper(:new.e_nom); 
	:new.e_prenom := upper(:new.e_prenom);
	/* Si c'est un insert */
	IF INSERTING THEN
		/* Si la date est null alors on met la date du jour */
		IF :new.e_date_dossier is null then 
			:new.e_date_dossier := current_date();
		END IF;
		/* On génére la clé primaire par une séquence */
		SELECT sequence_id_eleve.nextval INTO :new.eleve_pkey FROM dual;
	END IF;
	/* Si c'est un update */
	IF UPDATING THEN 
		/* Si la date est null, on la remplace par l'ancienne date */
		IF :new.e_date_dossier is null then 
			:new.e_date_dossier := :old.e_date_dossier;
		END IF;
		/* On remplace la clé primaire par l'ancienne pour éviter qu'elle soit changé */
		:new.eleve_pkey := :old.eleve_pkey;
	END IF; 
END;

/************************ Insertion et modification d'ELEVE ************************/
INSERT INTO ELEVE VALUES (null, 'LANDSCHOOT', 'Ludovic', '1995-08-29', '06.71.84.95.30', '2010-01-01', '2010-12-31');
INSERT INTO ELEVE VALUES (null, 'COILLIAUX', 'Thibault', '1999-09-21', '01.02.83.94.50', null, '2015-12-31');
INSERT INTO ELEVE VALUES (null, 'DELEPLANQUE', 'Dylan', '1990-10-08', '02.03.04.05.06', '2008-01-01', '2008-12-31');

UPDATE ELEVE
SET e_date_dossier = null
WHERE e_nom = 'LANDSCHOOT' AND e_prenom = 'Ludovic';

UPDATE ELEVE
SET eleve_pkey = 8
WHERE e_nom = 'DELEPLANQUE' AND e_prenom = 'Dylan';

/************************ Creation de nouveaux champs dans ELEVE ************************/
ALTER TABLE ELEVE ADD e_nb_km DECIMAL(4,1);
ALTER TABLE ELEVE ADD e_nbH_lecons INT;

UPDATE ELEVE SET e_nb_km = (select sum(t_nb_km) from trajet natural join eleve);
UPDATE ELEVE SET e_nbh_lecons = (select SUM(l_duree)/60 from lecon natural join eleve);

/************************ Triggers TRAJET ************************/
CREATE OR REPLACE TRIGGER after_insert_update_delete_trajet
AFTER INSERT OR UPDATE OR DELETE 
ON TRAJET
FOR EACH ROW
BEGIN
IF INSERTING THEN
	UPDATE ELEVE SET e_nb_km = e_nb_km + :new.t_nb_km;
END IF;
IF UPDATING THEN
	UPDATE ELEVE SET e_nb_km = e_nb_km - :old.t_nb_km + :new.t_nb_km;
END IF;
IF DELETING THEN 
	UPDATE ELEVE SET e_nb_km = e_nb_km - :old.t_nb_km;
END IF;
END;

/************************ Triggers lecon ************************/
CREATE OR REPLACE TRIGGER after_insert_update_delete_lecon
AFTER INSERT OR UPDATE OR DELETE 
ON LECON
FOR EACH ROW
BEGIN
IF INSERTING THEN
	UPDATE ELEVE SET e_nbh_lecons = e_nbh_lecons + :new.l_duree;
END IF;
IF UPDATING THEN
	UPDATE ELEVE SET e_nbh_lecons = e_nbh_lecons - :old.l_duree + :new.l_duree;
END IF;
IF DELETING THEN 
	UPDATE ELEVE SET e_nbh_lecons = e_nbh_lecons - :old.l_duree;
END IF;
END;

/************************ Insertion et modification de MONITEUR ************************/
INSERT INTO MONITEUR VALUES (1, 'MITCHEL', 'Alain');
INSERT INTO MONITEUR VALUES (1, 'ALFONSE', 'Jacque');

/************************ Insertion et modification de TRAJET ************************/
INSERT INTO TRAJET VALUES (1, 1, '2010-10-20', 50, 'route');
INSERT INTO TRAJET VALUES (2, 1, '2010-11-20', 55, 'ville');
INSERT INTO TRAJET VALUES (3, 2, '2015-10-20', 48, 'ville');
INSERT INTO TRAJET VALUES (4, 2, '2008-11-20', 46, 'autoroute');
INSERT INTO TRAJET VALUES (5, 3, '2008-10-20', 53, 'route');

UPDATE TRAJET
SET t_nb_km = t_nb_km + 3;
WHERE t_id = 1;

/************************ Insertion et modification de LECON ************************/
INSERT INTO TRAJET VALUES (1, 1, '2010-10-20', 50, 'route');
INSERT INTO TRAJET VALUES (2, 1, '2010-11-20', 55, 'ville');
INSERT INTO TRAJET VALUES (3, 2, '2015-10-20', 48, 'ville');
INSERT INTO TRAJET VALUES (4, 2, '2008-11-20', 46, 'autoroute');
INSERT INTO TRAJET VALUES (5, 3, '2008-10-20', 53, 'route');

UPDATE TRAJET
SET t_nb_km = t_nb_km + 3;
WHERE t_id = 1;