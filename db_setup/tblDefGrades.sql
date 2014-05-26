DROP TABLE tblDefGrades;

#
# Table               : tblDefGrades
# Description         : Grade Defintions
#---------------------
# intGradeNO	      : Grade NO
# intAssocID	      : Association ID
# intGrade	      : Grade ID
# strName	      : Name of Grade
#

CREATE table tblDefGrades (
    intGradeNO	    INTEGER NOT NULL AUTO_INCREMENT,
    intAssocID	    INTEGER NOT NULL DEFAULT 0,
    intGrade	    INTEGER NOT NULL DEFAULT 0,
    strName         VARCHAR (50) NOT NULL,
PRIMARY KEY (intGradeNO),
KEY index_lookup(intGrade, intAssocID)
);
