-- Open the dataset for initial inspection -- 

SELECT * FROM [Portfolio Project]..NashvilleHousing


-- First thing I notice is the date. Let's fix that column by removing the unused timestamp.


--First I select SaleDate and convert it to the format I think I want. It looks good
SELECT SaleDate,CONVERT(Date,SaleDate) FROM [Portfolio Project]..NashvilleHousing

--Now I add another Column called "SaleDateConverted" with the data type Date
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

--And finally we update the new SaleDateConverted Column with our converted dates.

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


--Next thing I notice is the PropertyAddress. It seems to be including the city as well.
--Let's take a look first

SELECT * FROM [Portfolio Project]..NashvilleHousing
ORDER BY ParcelID

--It seems like there are NULL values for addresses even when we should know them. 
--Some columns have NULL address, but a ParcelID that is shared with another ROW and in that ROW we have the address.
--So let's make our data more useful by populating these NULL fields with the correct address.



--First, We do a self join on ParcelID and Unique ID. ParcelID is the one that repeats, Unique ID does not, so we can use that to match addresses.
-- We only want to see NULL results in table 1 and match it with the matching ParcelID's from table 2 with Non-Null addresses.
SELECT NH1.ParcelID,NH2.ParcelID, NH1.PropertyAddress,NH2.PropertyAddress, ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
FROM [Portfolio Project]..NashvilleHousing NH1
JOIN [Portfolio Project]..NashvilleHousing NH2
	ON NH1.ParcelID = NH2.ParcelID
	AND NH1.[UniqueID ] != NH2.[UniqueID ]
WHERE NH1.PropertyAddress is NULL

--Now we UPDATE our PropertyAddress by updating table 1 and filling it with the results from the self joined table 2. 
--The result should be that when we run the above query, we return NO results because there are no longer any NULL values.
UPDATE NH1
SET PropertyAddress = ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
FROM [Portfolio Project]..NashvilleHousing NH1
JOIN [Portfolio Project]..NashvilleHousing NH2
	ON NH1.ParcelID = NH2.ParcelID
	AND NH1.[UniqueID ] != NH2.[UniqueID ]
WHERE NH1.PropertyAddress is NULL


--Next I want to fix the address by breaking it up into a more usable format.

SELECT PropertyAddress
FROM [Portfolio Project]..NashvilleHousing


--This query creates 2 substrings of the Address. It does this by searching for a Comma, and then ending the first string there.
--We must add -1 to the end of the CHARINDEX function because otherwise it would include the comma. 
--Same applies for the second column, but instead we ADD one to remove the leading comma.
SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,Len(PropertyAddress)) as City
FROM [Portfolio Project]..NashvilleHousing


--Now we add these new columns to the table.

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplit NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertyCitySplit NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyCitySplit = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,Len(PropertyAddress))



--Now Let's take a look at the OwnerAddress column

SELECT OwnerAddress
FROM [Portfolio Project]..NashvilleHousing

--It seems that we need to seperate this stuff out again. I'd rather not have it all in one column.
--So we're going to use PARSENAME for this which is a built in SQL function, but it's important to note that PARSENAME looks for Period characters '.' to decide when to start a new column.
--So in order for this to work, we must first REPLACE the ','s in OwnerAddress with '.'s in order for PARSENAME to work.
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM [Portfolio Project]..NashvilleHousing

--Now let's add these columns to our data


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


--Now let's look at the SoldAsVacant column.

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SoldAsVacant


--It looks like most of the responses are either "yes" or "no" but there are also some that are "y" or "n" 
--so let's change that to be all "yes" and "no" instead of having multiple ways to represent this boolean.

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM [Portfolio Project]..NashvilleHousing

--Looks good, now let's update the table.
--And to make sure the change worked, we can run the DISTINCT query from above again.

UPDATE NashvilleHousing

SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END




--Next, let's remove duplicates from the Data. 
--This doesn't always make sense, and in many cases you want to just use TempTables for this if you need to remove duplicates for some reason.
--However, I happen to know that in the case of this data, we can safely remove duplicates and lose no value in the data set. 
--We use a CTE here so we can use the ROW_NUMBER() Function.
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM [Portfolio Project]..NashvilleHousing
)

DELETE FROM RowNumCTE
WHERE row_num > 1




--Now let's delete unused columns. 
--Again, this is not necesarilly something you must do.
--Sometimes columns are blank for a reason, however in this case I know that the unused columns are not needed.
--We're also going to remove the redundant columns.
--Throughout these querys we have been breaking columns out into multiple other columns to make them more readable and usable for analysis. 
-- Now that we've done that, we can delete the original dirty data. 
--Again, creating a view here is an option, but I don't need the original data and what matters to me is usability.

ALTER TABLE [Portfolio Project]..NashvilleHousing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress,SaleDate

SELECT * FROM [Portfolio Project]..NashvilleHousing





