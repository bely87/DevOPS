﻿sc stop "1C:Enterprise 8.3 Server Agent"
Remove-Item -Path -Path "C:\Program Files\1cv8\srvinfo"
New-Item -ItemType directory -Path "e:\Program Files\1cv8\srvinfo"
New-Item -Path "C:\Program Files\1cv8\srvinfo" -ItemType SymbolicLink -Value "e:\Program Files\1cv8\srvinfo"
sc config "1C:Enterprise 8.3 Server Agent (x86-64)" obj= "nextcar\srv-te-app-01-1c" password= "XVJb9rhRtz"
sc start "1C:Enterprise 8.3 Server Agent"