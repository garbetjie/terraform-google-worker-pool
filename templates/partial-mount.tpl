type=${mount.type == null ? "volume" : mount.type},src=${mount.src},dst=${mount.target}${mount.readonly == true ? ",readonly" : ""}