UPDATE tblSystemConfig SET strValue = 'Sign into Pelipaikka' where strOption = 'loginWelcomeMessage';
UPDATE tblSystemConfig SET strValue = '<h1>Pelipaikka</h1>' where strOption = 'HeaderSystemName';
UPDATE tblSystemConfig SET strValue = 'http://www.palloliitto.fi' WHERE strOption = 'ma_website';
UPDATE tblSystemConfig SET strValue = '+358 9 742151' WHERE strOption = 'ma_phone_number';
UPDATE tblSystemConfig SET strValue = 'tuki@palloliitto.fi' WHERE strOption = 'help_desk_email';
UPDATE tblSystemConfig SET strValue = '+358 9 31585000' WHERE strOption = 'help_desk_phone_number';

