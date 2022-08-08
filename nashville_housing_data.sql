/*Cleaning Data in SQl*/

select *
from nashville_housing_data;


#------------------Populate Property Address data----------------------------
Select PropertyAddress
from nashville_housing_data;


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
       IFNULL(a.PropertyAddress, b.PropertyAddress)
from nashville_housing_data a
join nashville_housing_data b
on a.ParcelID = b.ParcelID
where a.UniqueID != b.UniqueID
and a.PropertyAddress is null;


#-------------Breaking out Address into Individual Columns (Address, City, State)-------------
Select PropertyAddress
from nashville_housing_data;

select substring_index(PropertyAddress, ',', 1) as Address,
       substring_index(PropertyAddress, ',', -1) as City
from nashville_housing_data;

/*
select UniqueID, ParcelID, PropertyAddress, PropertySplit_Address, City
from nashville_housing_data;

alter table nashville_housing_data
add City Varchar(200);

Update nashville_housing_data
set City = substring_index(PropertyAddress, ',', -1)
where PropertyAddress = PropertyAddress;
*/



#--------------move the new created columns to the right position---------------

alter table nashville_housing_data
modify column PropertySplit_Address varchar(200) after PropertyAddress;

alter table nashville_housing_data
modify column City varchar(200) after PropertySplit_Address;



#-------------Split OwnerAddress to Address, City, State---------------------------

select PropertyAddress,PropertySplit_Address,city, OwnerAddress, OwnerAddress_Split,
       OwnerAddress_City, OwnerAddress_State
from nashville_housing_data;


select substring_index(OwnerAddress, ',', 1) as OwnerAddress_Split,
       substring_index(substring_index(OwnerAddress, ',', 2), ',', -1) as OwnerAddress_City,
       substring_index(OwnerAddress, ',', -1) as State
from nashville_housing_data;

#----1.Add column 'OwnerAddress_Split'
alter table nashville_housing_data
add OwnerAddress_Split varchar(200);

update nashville_housing_data
set OwnerAddress_Split = substring_index(OwnerAddress, ',', 1)
where OwnerAddress = OwnerAddress;

#----2.Add column 'OwnerAddress_City'
alter table nashville_housing_data
add OwnerAddress_City varchar(200);

update nashville_housing_data
set OwnerAddress_City = substring_index(substring_index(OwnerAddress, ',', 2), ',', -1)
where OwnerAddress = OwnerAddress;

#----3.Add column 'OwnerAddress_State'
alter table nashville_housing_data
add OwnerAddress_State varchar(200);

update nashville_housing_data
set OwnerAddress_State = substring_index(OwnerAddress, ',', -1)
where OwnerAddress = OwnerAddress;




#--------------move the new created columns to the right position---------------

alter table nashville_housing_data
modify column OwnerAddress_Split varchar(200) after OwnerAddress;

alter table nashville_housing_data
modify column OwnerAddress_City varchar(200) after OwnerAddress_Split;

alter table nashville_housing_data
modify column OwnerAddress_State varchar(200) after OwnerAddress_City;



#--------------Change Y and N to Yes and No in 'Sold as Vacant' field

select distinct SoldAsVacant, count(SoldAsVacant)
from nashville_housing_data
group by SoldAsVacant;

select SoldAsVacant,
    case when SoldAsVacant = 'Y' then SoldAsVacant = 'Yes'
        when SoldAsVacant = 'N' then SoldAsVacant = 'No'
    else SoldAsVacant
    end
from nashville_housing_data;



#-----------------Remove Duplicates-------------------------------

With RN_CTE as (select *,
           row_number() over (partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               order by UniqueID) rn
    from nashville_housing_data)

#IMPORTANT!!!New MySQL can't directly delete or update to CTE
delete from nashville_housing_data using nashville_housing_data
    join rn_cte rc
    on nashville_housing_data.uniqueid = rc.uniqueid
    where rn > 1;


#-----------------Delete unused columns---------------------

alter table nashville_housing_data
drop column OwnerAddress;

alter table nashville_housing_data
drop column PropertyAddress;

select * from nashville_housing_data