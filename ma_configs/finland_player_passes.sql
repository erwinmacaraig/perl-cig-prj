####PLAYER PASSES born BEFORE 1995
UPDATE tblRegistrationItem SET intRequired=1, intUseExistingThisEntity=1, intUseExistingAnyEntity=1, intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='59|71|137|141' WHERE strItemType = 'PRODUCT' and intID IN (59,71); #$45
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='59|71|137|141', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (65,77); #$0



####PLAYER PASSES born BETWEEN 1996 and 2003
UPDATE tblRegistrationItem SET intRequired=1, intUseExistingThisEntity=1, intUseExistingAnyEntity=1, intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='60|72|138|142' WHERE strItemType = 'PRODUCT' and intID IN (60,72); #$40
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='60|72|138|142', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (66,78); #$0



####PLAYER PASSES born BETWEEN 2004 and 2015
#$25
UPDATE tblRegistrationItem SET intRequired=1, intUseExistingThisEntity=1, intUseExistingAnyEntity=1, intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='61|73' WHERE strItemType = 'PRODUCT' and intID IN (61,73); 
UPDATE tblRegistrationItem SET intRequired=1, intUseExistingThisEntity=1, intUseExistingAnyEntity=1, intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='59|71|137|141|60|72|138|142|61|73' WHERE strItemType = 'PRODUCT' and intID IN (61,73);  
#$0
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='61|73', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (67,79);  
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='59|71|137|141|60|72|138|142|61|73', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (67,79); 





#HOBBY Player pass with AMOUNT $10
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='62|74|59|71|137|141|60|72|138|142|61|73' WHERE strItemType = 'PRODUCT' and intID IN (62,74);
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='62|74|59|71|137|141|60|72|138|142|61|73', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (68,80);  

#HOBBY Player pass with AMOUNT $8
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='63|75|59|71|137|141|60|72|138|142|61|73' WHERE strItemType = 'PRODUCT' and intID IN (63,75);
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='63|75|59|71|137|141|60|72|138|142|61|73', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (69,81);  

#HOBBY Player pass with AMOUNT $5
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='64|76|59|71|137|141|60|72|138|142|61|73' WHERE strItemType = 'PRODUCT' and intID IN (64,76);
UPDATE tblRegistrationItem SET intItemUsingPaidProductFilter=1, strItemActiveFilterPaidProducts='64|76|59|71|137|141|60|72|138|142|61|73', intItemPaidProducts=1 WHERE strItemType = 'PRODUCT' and intID IN (70,82);  






#UPDATE tblRegistrationItem SET intRequired=1, intUseExistingThisEntity=1, intUseExistingAnyEntity=1 WHERE strItemType = 'PRODUCT' and intID IN (59,60,61,71,72,73);
#
### MAYBE THIS ONE ?
#UPDATE tblRegistrationItem SET intFilterFromAge=0, intFilterToAge=0  WHERE strItemType = 'PRODUCT' and intID IN (59,60,61,71,72,73);
