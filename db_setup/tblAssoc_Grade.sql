DROP TABLE tblAssoc_Grade;
 
#
# Table               : tblAssoc_Grade
# Description         : Grades that an association has 
#---------------------
# intAssocGradeID     : Automatic Member Team ID 
# intAssocID          : Associations ID
# strGradeDesc        : Grade Description
#
CREATE table tblAssoc_Grade (
    intAssocGradeID  INT NOT NULL AUTO_INCREMENT,
    intAssocID       INT NOT NULL,
    strGradeDesc     VARCHAR(150),
PRIMARY KEY (intAssocGradeID),
KEY index_intAssocID(intAssocID)
);
 
