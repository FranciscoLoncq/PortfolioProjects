/* Cleaning Data in SQL Queries*/

Select * 
From dbo.[Nashville Housing Data for Data Cleaning]

/* Standarizing Date Format from Datetime to Date*/
Select SaleDate, convert (Date, Saledate)
From dbo.[Nashville Housing Data for Data Cleaning]

Update dbo.[Nashville Housing Data for Data Cleaning]
SET SaleDate = convert (Date, Saledate)

/*Populating Property Address Data*/
Select *
From dbo.[Nashville Housing Data for Data Cleaning]
--WHERE PropertyAddress IS NULL;
ORDER BY ParcelID

--IF ADDRESS IS NULL AND THERE IS ANOTHER IDENTICAL PARCELID, WE POPULATE THE NULL CELL WITH THAT SAME VALUE USING A SELF JOIN--
Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
From dbo.[Nashville Housing Data for Data Cleaning] A
JOIN dbo.[Nashville Housing Data for Data Cleaning] B
on A.ParcelID = B.ParcelID
AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL;

--we then update the table in order to populate all nulls for property address--

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
From dbo.[Nashville Housing Data for Data Cleaning] A
JOIN dbo.[Nashville Housing Data for Data Cleaning] B
on A.ParcelID = B.ParcelID
AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL;

/* Breaking out Address into Individual Columns (Address, City, State)*/

SELECT SUBSTRING (PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS ADDRESS
From dbo.[Nashville Housing Data for Data Cleaning]

--WE OBTAIN THE ADDRESS COLUMN, NOW WE NEED THE CITY--
SELECT SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+2, CHARINDEX(',',PropertyAddress)) AS ADDRESS
From dbo.[Nashville Housing Data for Data Cleaning]

--UPDATING THE TABLE TO HAVE ADDRESS AND CITY COLUMNS SEPARATED--

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ADD PropertySplitAddress Nvarchar (255);

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING (PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1);

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ADD PropertySplitCity Nvarchar (255);

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET PropertySplitCity = SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+2, CHARINDEX(',',PropertyAddress));


/* Doing the same column split for OwnerAddress*/

Select OwnerAddress
From dbo.[Nashville Housing Data for Data Cleaning]

SELECT 
PARSENAME(OwnerAddress,1)
From dbo.[Nashville Housing Data for Data Cleaning]

--SINCE PARSENAME COMMAND ONLY LOOKS UP FOR PERIODS AND WE HAVE COMMAS AS DELIMETERS, WE CAN REPLACE COMMAS FOR PERIODS--

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
From dbo.[Nashville Housing Data for Data Cleaning]

--UPDATING THE DBASE--
ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitAddress Nvarchar (255)

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitCity Nvarchar (255)

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitState Nvarchar (255)

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

/* SoldAsVacant Row is showing as binary , only populated with 0s and 1s */
--We want values to be YES or NO--

SELECT DISTINCT (SoldAsVacant), count(SoldAsVacant)
FROM dbo.[Nashville Housing Data for Data Cleaning]
group by SoldAsVacant
order by 2

--in order for the case when to work, we need to alter the table and change the bit values into varchar so we can have yes or no in the column--

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
ALTER COLUMN SoldAsVacant Varchar(3)

SELECT DISTINCT (SoldAsVacant)
, CASE WHEN SoldAsVacant = 0 THEN 'NO'
	 WHEN SoldAsVacant = 1 THEN 'YES'
	 ELSE SoldAsVacant
	 END 
FROM dbo.[Nashville Housing Data for Data Cleaning]

-- updating into new column--

UPDATE dbo.[Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 0 THEN 'NO'
	 WHEN SoldAsVacant = 1 THEN 'YES'
	 ELSE SoldAsVacant
	 END 

/*Removing Duplicates using a CTE*/

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From dbo.[Nashville Housing Data for Data Cleaning]

)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--104 duplicate rows--

-- Delete Unused Columns

Select *
From dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

