function [result] = versionCheck(v, maj, min)

    tokens = regexp(v, '[^\d]*(\d+)[^\d]+(\d+).*', 'tokens');
    majToken = tokens{1}(1);
    minToken = tokens{1}(2);
    major = str2num(majToken{1});
    minor = str2num(minToken{1});
    result = major > maj || (major == maj && minor >= min);
end      