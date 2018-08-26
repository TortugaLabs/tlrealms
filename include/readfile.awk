
function read_file(dbfile, fname) {
  delete dbfile;
  while ((getline < fname) > 0) {
    if (length($0) == 0) continue;
    if (substr($0,0,1) == "#") continue;
    dbfile[$1] = $0;
  }
  close(fname);
}
