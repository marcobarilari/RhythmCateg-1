function checkOctave()
% check if Octave version is above 5.1 for couple of functions in this repo
% to work/run


desired_oct_vers.major = 5;
desired_oct_vers.minor = 1;
desired_oct_vers.point = 0;

oct_vers = version;

major_OK = str2double(oct_vers(1)) < desired_oct_vers(1).major; % major version is too old
minor_OK = str2double(oct_vers(1)) == desired_oct_vers(1).major ...
    && str2double(oct_vers(3)) == desired_oct_vers(1).minor; % major version is OK but not minor

if any([major_OK minor_OK])
    printf('your octave version is SO old I have to rewrite functions for you... Seriously\n')
end

end