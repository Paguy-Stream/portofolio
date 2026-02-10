/* Question 1 :
Créer la vue "AlbumsArtists" qui permet d'afficher tous les titres des albums ainsi que le nom de l'artiste associé. */

USE devoir1;

-- Créer la vue
CREATE OR REPLACE VIEW AlbumsArtists AS
SELECT 
    a.Title AS TitreAlbum,
    ar.Name AS NomArtiste
FROM 
    Album a
INNER JOIN 
    Artist ar ON a.ArtistId = ar.ArtistId;

-- Tester la vue
SELECT * FROM AlbumsArtists LIMIT 0, 1000;





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 2 :
Créer la vue "v_billings" qui résume les données des factures et des articles. 
Elle affiche le numéro de facture, sa date ainsi que le total de celle-ci. */

-- Créer la vue v_billings
CREATE OR REPLACE VIEW v_billings AS
SELECT 
    i.InvoiceId AS NumeroFacture,
    i.InvoiceDate AS DateFacture,
    SUM(il.UnitPrice * il.Quantity) AS TotalFacture
FROM 
    invoice i
INNER JOIN 
    invoiceline il ON i.InvoiceId = il.InvoiceId
GROUP BY 
    i.InvoiceId, i.InvoiceDate
ORDER BY 
    i.InvoiceDate DESC;

-- Afficher toutes les factures
SELECT * FROM v_billings;

-- Afficher les 10 premières factures
SELECT * FROM v_billings LIMIT 10;

-- Afficher les factures avec le total le plus élevé
SELECT * FROM v_billings ORDER BY TotalFacture DESC LIMIT 10;

-- Compter le nombre total de factures
SELECT COUNT(*) AS NombreTotalFactures FROM v_billings;

-- Afficher le total des ventes par date
SELECT DateFacture, SUM(TotalFacture) AS TotalJournalier
FROM v_billings 
GROUP BY DateFacture 
ORDER BY DateFacture DESC;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 3 :
Créer la vue "v_albums" qui affiche la durée de chaque album. Cette vue affiche :
-  le nom de l'album
-  sa durée en minutes
Créer la vue "v_albums2" qui affiche les mêmes informations, mais cette fois affiche la durée en minutes et secondes. Cette
vue utilise la fonction "ConvertMsToMinutesAndSeconds". */



-- Premièrement, créons la fonction ConvertMsToMinutesAndSeconds
-- Supprimer la fonction si elle existe
DROP FUNCTION IF EXISTS ConvertMsToMinutesAndSeconds;

DELIMITER $$

CREATE FUNCTION ConvertMsToMinutesAndSeconds(milliseconds INT) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE total_seconds INT;
    DECLARE minutes_part INT;
    DECLARE seconds_part INT;
    
    SET total_seconds = FLOOR(milliseconds / 1000);
    SET minutes_part = FLOOR(total_seconds / 60);
    SET seconds_part = total_seconds % 60;
    
    RETURN CONCAT(minutes_part, 'm ', seconds_part, 's');
END$$

DELIMITER ;

-- Vue v_albums : durée en minutes
CREATE OR REPLACE VIEW v_albums AS
SELECT 
    a.Title AS NomAlbum,
    ROUND(SUM(t.Milliseconds) / (1000 * 60), 2) AS DureeMinutes
FROM 
    Album a
INNER JOIN 
    Track t ON a.AlbumId = t.AlbumId
GROUP BY 
    a.AlbumId, a.Title
ORDER BY 
    DureeMinutes DESC;

-- Vue v_albums2 : durée en minutes et secondes
CREATE OR REPLACE VIEW v_albums2 AS
SELECT 
    a.Title AS NomAlbum,
    ROUND(SUM(t.Milliseconds) / (1000 * 60), 2) AS DureeMinutes,
    ConvertMsToMinutesAndSeconds(SUM(t.Milliseconds)) AS DureeMinutesSecondes
FROM 
    Album a
INNER JOIN 
    Track t ON a.AlbumId = t.AlbumId
GROUP BY 
    a.AlbumId, a.Title
ORDER BY 
    DureeMinutes DESC;

-- Testons la fonction
SELECT ConvertMsToMinutesAndSeconds(253000) AS DureeExemple;

-- Affichons v_albums (durée en minutes)
SELECT * FROM v_albums LIMIT 10;

-- Affichons v_albums2 (durée en minutes et minutes:secondes)
SELECT * FROM v_albums2 LIMIT 10;

-- Les albums les plus longs
SELECT * FROM v_albums2 ORDER BY DureeMinutes DESC LIMIT 5;

-- Les albums les plus courts
SELECT * FROM v_albums2 ORDER BY DureeMinutes ASC LIMIT 5;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Questions sur les CTE*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 1 :
Créer une requête utilisant une CTE permettant de savoir quels sont les pays dans lesquels les ventes sont les plus importantes.
Elle devra rassembler des données sur les ventes effectuées par les clients de différents pays. Plus précisément, pour
chaque pays, nous voulons obtenir :
-  le nombre total de clients
-  la valeur totale des ventes
-  la valeur moyenne des ventes par client
-  le nombre moyen de commandes
Page 3 sur 10
Sujet SQL M2 MECEN
L'analyse préliminaire montre qu'un certain nombre de pays n'ont qu'un seul client. Nous allons regrouper les clients de
ces pays dans la catégorie "Other" dans l'analyse. Vous ferez en sorte que le regroupement "Other" soit affiché en dernier et
que les données soient triées dans l'ordre décroissant du total des ventes. */

WITH StatistiquesPays AS (
    SELECT 
        c.Country AS Pays,
        COUNT(DISTINCT c.CustomerId) AS NbClients,
        COUNT(DISTINCT i.InvoiceId) AS NbCommandes,
        SUM(il.UnitPrice * il.Quantity) AS TotalVentes
    FROM customer c
    LEFT JOIN invoice i ON c.CustomerId = i.CustomerId
    LEFT JOIN invoiceline il ON i.InvoiceId = il.InvoiceId
    GROUP BY c.Country
),
PaysRegroupes AS (
    SELECT 
        CASE 
            WHEN NbClients > 1 THEN Pays
            ELSE 'Other' 
        END AS PaysGroupe,
        NbClients,
        TotalVentes,
        NbCommandes
    FROM StatistiquesPays
)
SELECT 
    PaysGroupe AS Pays,
    SUM(NbClients) AS "Nombre Total de Clients",
    ROUND(SUM(TotalVentes), 2) AS "Valeur Totale des Ventes",
    ROUND(SUM(TotalVentes) / SUM(NbClients), 2) AS "Valeur Moyenne par Client",
    ROUND(SUM(NbCommandes) / SUM(NbClients), 2) AS "Nombre Moyen de Commandes"
FROM PaysRegroupes
GROUP BY PaysGroupe
ORDER BY 
    CASE WHEN PaysGroupe = 'Other' THEN 1 ELSE 0 END,
    SUM(TotalVentes) DESC;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 2 :
Identifions les 10 genres musicaux les plus populaires parmi les clients des cinq pays suivants : États-Unis, Canada, Brésil,
France et Allemagne. Plus précisément, pour chaque genre, nous voulons obtenir :
-  le nombre de pistes vendues
-  ce nombre exprimé en pourcentage du total général */

WITH VentesParGenre AS (
    SELECT 
        g.Name AS Genre,
        COUNT(*) AS NbPistesVendues,
        (SELECT COUNT(*) 
         FROM invoiceline il2
         INNER JOIN invoice i2 ON il2.InvoiceId = i2.InvoiceId
         INNER JOIN customer c2 ON i2.CustomerId = c2.CustomerId
         WHERE c2.Country IN ('USA', 'Canada', 'Brazil', 'France', 'Germany')
        ) AS TotalPistes
    FROM 
        invoiceline il
    INNER JOIN track t ON il.TrackId = t.TrackId
    INNER JOIN genre g ON t.GenreId = g.GenreId
    INNER JOIN invoice i ON il.InvoiceId = i.InvoiceId
    INNER JOIN customer c ON i.CustomerId = c.CustomerId
    WHERE 
        c.Country IN ('USA', 'Canada', 'Brazil', 'France', 'Germany')
    GROUP BY 
        g.Name
)
SELECT 
    Genre AS "Genre Musical",
    NbPistesVendues AS "Nombre de Pistes Vendues",
    ROUND((NbPistesVendues / TotalPistes) * 100, 2) AS "Pourcentage du Total"
FROM 
    VentesParGenre
ORDER BY 
    NbPistesVendues DESC
LIMIT 10;





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 3 :
Créer une requête utilisant une CTE qui permet d'afficher la moyenne des paniers moyens par pays. Trier les résultats
par valeur moyenne, dans l'ordre croissant. */

WITH PanierMoyenParPays AS (
    SELECT 
        c.Country AS Pays,
        ROUND(AVG(il.UnitPrice * il.Quantity), 2) AS ValeurPanierMoyen
    FROM 
        customer c
    INNER JOIN 
        invoice i ON c.CustomerId = i.CustomerId
    INNER JOIN 
        invoiceline il ON i.InvoiceId = il.InvoiceId
    GROUP BY 
        c.Country
)
SELECT 
    Pays AS "Pays",
    ValeurPanierMoyen AS "Panier Moyen (€)"
FROM 
    PanierMoyenParPays
ORDER BY 
    ValeurPanierMoyen ASC;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 4 :
Créer une requête utilisant une CTE, permettant d'obtenir par année, par trimestre et par pays le nombre de bons
clients. Un bon client est un client pour lequel le montant d'achat moyen d'un est d'au moins 3,00 euros. Classer les résultats
par année et par trimestre et par nombre de bons clients. */

WITH StatistiquesAchats AS (
    SELECT 
        c.CustomerId,
        c.Country AS Pays,
        CONCAT(c.FirstName, ' ', c.LastName) AS NomClient,
        YEAR(i.InvoiceDate) AS Annee,
        QUARTER(i.InvoiceDate) AS Trimestre,
        COUNT(i.InvoiceId) AS NombreAchats,
        SUM(il.UnitPrice * il.Quantity) AS TotalAchats,
        AVG(il.UnitPrice * il.Quantity) AS MontantMoyenAchat
    FROM 
        customer c
    INNER JOIN 
        invoice i ON c.CustomerId = i.CustomerId
    INNER JOIN 
        invoiceline il ON i.InvoiceId = il.InvoiceId
    GROUP BY 
        c.CustomerId, c.Country, NomClient, YEAR(i.InvoiceDate), QUARTER(i.InvoiceDate)
),
BonsClientsParPeriode AS (
    SELECT 
        Pays,
        Annee,
        Trimestre,
        COUNT(CustomerId) AS NombreBonsClients,
        SUM(TotalAchats) AS ChiffreAffairesTotal,
        ROUND(AVG(MontantMoyenAchat), 2) AS MontantMoyenGeneral
    FROM 
        StatistiquesAchats
    WHERE 
        MontantMoyenAchat >= 3.00
    GROUP BY 
        Pays, Annee, Trimestre
)
SELECT 
    Pays AS "Pays",
    Annee AS "Année",
    Trimestre AS "Trimestre",
    NombreBonsClients AS "Nombre de Bons Clients",
    ChiffreAffairesTotal AS "Chiffre d'Affaires Total",
    MontantMoyenGeneral AS "Montant Moyen par Achat"
FROM 
    BonsClientsParPeriode
ORDER BY 
    Annee DESC, 
    Trimestre DESC, 
    NombreBonsClients DESC;
    
    
    




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 5 :
Créer une requête utilisant 2 CTE (une seule peu suffire) qui permet d'afficher pour les USA le nombre de pistes vendues
par genre. Vous devez afficher :
- le nom du genre
- le nombre de pistes vendues
- le pourcentage que représente le nombre de piste par rapport au nombre de piste total */

WITH VentesGenresUSA AS (
    SELECT 
        g.Name AS Genre,
        COUNT(il.InvoiceLineId) AS NombrePistesVendues
    FROM 
        invoiceline il
    INNER JOIN 
        track t ON il.TrackId = t.TrackId
    INNER JOIN 
        genre g ON t.GenreId = g.GenreId
    INNER JOIN 
        invoice i ON il.InvoiceId = i.InvoiceId
    INNER JOIN 
        customer c ON i.CustomerId = c.CustomerId
    WHERE 
        c.Country = 'USA'
    GROUP BY 
        g.Name
),
TotalPistesUSA AS (
    SELECT 
        SUM(NombrePistesVendues) AS TotalGeneral
    FROM 
        VentesGenresUSA
)
SELECT 
    vg.Genre AS "Genre Musical",
    vg.NombrePistesVendues AS "Nombre de Pistes Vendues",
    ROUND((vg.NombrePistesVendues / tg.TotalGeneral) * 100, 2) AS "Pourcentage du Total (%)"
FROM 
    VentesGenresUSA vg
CROSS JOIN 
    TotalPistesUSA tg
ORDER BY 
    vg.NombrePistesVendues DESC;





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Questions sur les procédures stockées*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 1 : 
Créer une procédure stockée "GetAlbumsByArtist" qui prend un nom d'artiste en entrée et retourne la liste de ses
albums.
*/

-- Supprimer la procédure si elle existe déjà
DROP PROCEDURE IF EXISTS GetAlbumsByArtist;

DELIMITER $$

CREATE PROCEDURE GetAlbumsByArtist(IN artist_name VARCHAR(120))
BEGIN
    SELECT 
        a.AlbumId,
        a.Title AS TitreAlbum,
        ar.Name AS Artiste,
        a.ArtistId
    FROM 
        Album a
    INNER JOIN 
        Artist ar ON a.ArtistId = ar.ArtistId
    WHERE 
        ar.Name LIKE CONCAT('%', artist_name, '%')
    ORDER BY 
        a.Title;
END$$

DELIMITER ;

-- Appeler la procédure
CALL GetAlbumsByArtist('AC/DC');



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 2 : 
Créer une procédure stockée "GetTotalTracksCount" qui calcule le nombre total de pistes dans la base de données et
stocke le résultat dans une variable de sortie.
*/

-- Supprimer la procédure si elle existe déjà
DROP PROCEDURE IF EXISTS GetTotalTracksCount;

DELIMITER $$

CREATE PROCEDURE GetTotalTracksCount(OUT total_tracks INT)
BEGIN
    SELECT COUNT(*) INTO total_tracks
    FROM track;
END$$

DELIMITER ;

-- Appeler la procédure et récupérer le résultat
CALL GetTotalTracksCount(@nombre_pistes);

-- Afficher le résultat
SELECT @nombre_pistes AS "Nombre total de pistes";




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 3 : 
Créer une procédure stockée "GetAlbumDetails" qui prend un ID d'album en entrée et retourne le nom de l'album et le
nombre de piste de ce dernier.*/


DROP PROCEDURE IF EXISTS GetAlbumDetails;

DELIMITER $$

CREATE PROCEDURE GetAlbumDetails(IN album_id INT)
BEGIN
    SELECT 
        a.AlbumId,
        a.Title AS NomAlbum,
        ar.Name AS Artiste,
        COUNT(t.TrackId) AS NombrePistes,
        ROUND(SUM(t.Milliseconds) / (1000 * 60), 2) AS DureeTotaleMinutes,
        ROUND(AVG(t.Milliseconds) / (1000 * 60), 2) AS DureeMoyenneMinutes,
        MIN(t.Name) AS ExemplePiste -- Première piste comme exemple
    FROM 
        Album a
    LEFT JOIN 
        Track t ON a.AlbumId = t.AlbumId
    LEFT JOIN
        Artist ar ON a.ArtistId = ar.ArtistId
    WHERE 
        a.AlbumId = album_id
    GROUP BY 
        a.AlbumId, a.Title, ar.Name;
END$$

DELIMITER ;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 4 : 
Créez une procédure stockée "GetArtistWithMostAlbums" pour récupérer le nom de l'artiste ayant le plus grand nombre
d'albums.
*/

-- Supprimer la procédure si elle existe déjà
DROP PROCEDURE IF EXISTS GetArtistWithMostAlbums;

DELIMITER $$

CREATE PROCEDURE GetArtistWithMostAlbums()
BEGIN
    SELECT 
        ar.ArtistId,
        ar.Name AS Artiste,
        COUNT(a.AlbumId) AS NombreAlbums
    FROM 
        Artist ar
    INNER JOIN 
        Album a ON ar.ArtistId = a.ArtistId
    GROUP BY 
        ar.ArtistId, ar.Name
    ORDER BY 
        NombreAlbums DESC
    LIMIT 1;
END$$

DELIMITER ;

-- Appeler la procédure
CALL GetArtistWithMostAlbums();







/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 5 :
Écrire une fonction stockée "CountAlbums" qui comptabilise le nombre d'album d'un artiste dont on fournit l'ID.
*/

-- Supprimons la fonction si elle existe déjà
DROP FUNCTION IF EXISTS CountAlbums;

DELIMITER $$

CREATE FUNCTION CountAlbums(artist_id INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE album_count INT;
    
    SELECT COUNT(*) 
    INTO album_count
    FROM Album 
    WHERE ArtistId = artist_id;
    
    RETURN album_count;
END$$

DELIMITER ;

-- Testons avec différents artistes
SELECT CountAlbums(1) AS "Nombre d'albums pour l'artiste 1";
SELECT CountAlbums(5) AS "Nombre d'albums pour l'artiste 5";
SELECT CountAlbums(10) AS "Nombre d'albums pour l'artiste 10";

-- Testons avec un artiste qui n'existe pas
SELECT CountAlbums(9999) AS "Nombre d'albums pour l'artiste 9999";






/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 6 :
Ecrire une fonction stockée "ConvertMsToMinutesAndSeconds" qui convertit une valeur transmise sous la forme d'une
durée en milisecondes en une valeur textuelle indiquant les minutes et les secondes.
*/
-- Supprimons la fonction si elle existe déjà
DROP FUNCTION IF EXISTS ConvertMsToMinutesAndSeconds;

DELIMITER $$

CREATE FUNCTION ConvertMsToMinutesAndSeconds(milliseconds INT) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE total_seconds INT;
    DECLARE minutes_part INT;
    DECLARE seconds_part INT;
    
    -- Calculer le nombre total de secondes
    SET total_seconds = FLOOR(milliseconds / 1000);
    
    -- Extraire les minutes et secondes
    SET minutes_part = FLOOR(total_seconds / 60);
    SET seconds_part = total_seconds % 60;
    
    -- Retourner le format "minutes:secondes"
    RETURN CONCAT(minutes_part, ':', LPAD(seconds_part, 2, '0'));
END$$

DELIMITER ;

-- Tester avec différentes valeurs
SELECT ConvertMsToMinutesAndSeconds(253000) AS "4:13";
SELECT ConvertMsToMinutesAndSeconds(125000) AS "2:05";
SELECT ConvertMsToMinutesAndSeconds(60000) AS "1:00";
SELECT ConvertMsToMinutesAndSeconds(30000) AS "0:30";
SELECT ConvertMsToMinutesAndSeconds(1000) AS "0:01";
SELECT ConvertMsToMinutesAndSeconds(0) AS "0:00";

-- Tester avec des valeurs de la base de données
SELECT 
    Name AS Piste,
    Milliseconds,
    ConvertMsToMinutesAndSeconds(Milliseconds) AS Duree
FROM Track 
LIMIT 10;




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 7 :
Créer une fonction stockée "nombre_subordonnes" qui calcule le nombre de subordonnés d'un employé.
*/

-- Supprimer la fonction si elle existe déjà
DROP FUNCTION IF EXISTS nombre_subordonnes;

DELIMITER $$

CREATE FUNCTION nombre_subordonnes(employe_id INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE subordonnes_count INT;
    
    SELECT COUNT(*)
    INTO subordonnes_count
    FROM employee
    WHERE ReportsTo = employe_id;
    
    RETURN subordonnes_count;
END$$

DELIMITER ;

-- Tester avec différents employés
SELECT nombre_subordonnes(1) AS "Subordonnés de l'employé 1";
SELECT nombre_subordonnes(2) AS "Subordonnés de l'employé 2";
SELECT nombre_subordonnes(3) AS "Subordonnés de l'employé 3";

-- Tester avec un employé qui n'existe pas
SELECT nombre_subordonnes(9999) AS "Subordonnés de l'employé 9999";




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Question 8 :
Créer une fonction stockée "GetTracksByAlbum" qui prend en entrée l'identifiant de l'album et retourne la liste de toutes
les pistes de cet album.
*/

USE devoir1;

-- Supprimer la fonction si elle existe déjà
DROP FUNCTION IF EXISTS GetTracksByAlbum;

DELIMITER $$

CREATE FUNCTION GetTracksByAlbum(album_id INT) 
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE tracks_list TEXT;
    DECLARE album_title VARCHAR(160);
    DECLARE album_exists INT;
    
    -- Vérifier si l'album existe
    SELECT COUNT(*) INTO album_exists
    FROM Album 
    WHERE AlbumId = album_id;
    
    IF album_exists = 0 THEN
        RETURN CONCAT('Album ID ', album_id, ' non trouvé');
    ELSE
        -- Récupérer le titre de l'album
        SELECT Title INTO album_title
        FROM Album 
        WHERE AlbumId = album_id;
        
        -- Construire la liste des pistes
        SELECT GROUP_CONCAT(
            CONCAT(t.TrackId, '. ', t.Name, ' (', 
                   FLOOR(t.Milliseconds/60000), ':', 
                   LPAD(FLOOR((t.Milliseconds%60000)/1000), 2, '0'), ')')
            ORDER BY t.TrackId
            SEPARATOR '\n'
        ) INTO tracks_list
        FROM Track t
        WHERE t.AlbumId = album_id;
        
        IF tracks_list IS NULL THEN
            RETURN CONCAT('Album "', album_title, '" ne contient aucune piste');
        ELSE
            RETURN CONCAT('Album: ', album_title, '\n\n', tracks_list);
        END IF;
    END IF;
END$$

DELIMITER ;

-- Tester avec différents albums
SELECT GetTracksByAlbum(1) AS "Pistes de l'album 1";
SELECT GetTracksByAlbum(5) AS "Pistes de l'album 5";
SELECT GetTracksByAlbum(10) AS "Pistes de l'album 10";

-- Tester avec un album qui n'existe pas
SELECT GetTracksByAlbum(9999) AS "Pistes de l'album 9999";

-- Tester avec un album sans pistes (si applicable)
SELECT GetTracksByAlbum(999) AS "Album sans pistes";

