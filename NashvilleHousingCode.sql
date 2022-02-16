--backup the table before doing any cleaning
IF OBJECT_ID('NashvilleHousingOriginal') IS NULL
BEGIN
CREATE TABLE [dbo].[NashvilleHousingOriginal](
	[UniqueID ] [float] NULL,
	[ParcelID] [nvarchar](255) NULL,
	[LandUse] [nvarchar](255) NULL,
	[PropertyAddress] [nvarchar](255) NULL,
	[SaleDate] [date] NULL,
	[SalePrice] [float] NULL,
	[LegalReference] [nvarchar](255) NULL,
	[SoldAsVacant] [nvarchar](255) NULL,
	[OwnerName] [nvarchar](255) NULL,
	[OwnerAddress] [nvarchar](255) NULL,
	[Acreage] [float] NULL,
	[TaxDistrict] [nvarchar](255) NULL,
	[LandValue] [float] NULL,
	[BuildingValue] [float] NULL,
	[TotalValue] [float] NULL,
	[YearBuilt] [float] NULL,
	[Bedrooms] [float] NULL,
	[FullBath] [float] NULL,
	[HalfBath] [float] NULL
) ON [PRIMARY]
END
-- Get a glimpse of the data
Select * from dbo.NashvilleHousing

-- Change the date format, remove the time

alter table dbo.NashvilleHousing
alter column  SaleDate Date

-- remove duplicates, if a record has the same parcelID, address and same sale day, it is considered a duplicate
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER(
	   PARTITION BY parcelID,
					saledate,
					PropertyAddress
		ORDER BY UniqueID

		) row_num
FROM dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--populate NULL values in PropertyAddress column
--notice when the parcelID has the same value, the propertyaddress should be the same
--have a glance of columns with NULL values
SELECT a.ParcelID, a.PropertyAddress, b.parcelID, b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.propertyaddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-- Breaking PropertyAddress into street, city, state
-- using two different ways to break PropertyAddress and OwnerAddress

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS street,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS city
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
ADD PropertyStreet NVARCHAR(255)
ALTER TABLE dbo.NashvilleHousing
ADD PropertyCity NVARCHAR(255)

UPDATE dbo.NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

UPDATE dbo.NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as street,
PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
ADD  OwnerStreet NVARCHAR(255)

ALTER TABLE dbo.NashvilleHousing
ADD OwnerCity NVARCHAR(255)

ALTER TABLE dbo.NashvilleHousing
ADD OwnerST NVARCHAR(255)

UPDATE dbo.NashvilleHousing
SET OwnerST =PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

UPDATE dbo.NashvilleHousing
SET OwnerCity =PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

UPDATE dbo.NashvilleHousing
SET OwnerStreet =PARSENAME(REPLACE(OwnerAddress,',','.'), 3)


-- Change Y and N to Yes and No in SoldAsVacant column

SELECT SoldAsVacant, COUNT( SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant

UPDATE dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END

--delete unused columns

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict 

select * 
from dbo.NashvilleHousing