import gccjit = gccjit.c; 

struct libhandle_t;
alias libhandle = libhandle_t*;

libhandle dlopen (const char* name, int flag);
void* dlsym (libhandle h, const char* symbol); 
enum loader_head = `
shared static this()
{
    auto lib_handle = dlopen("gccjit.so.0", 2); 

`;

enum loader_tail = `
}
`;

pragma(msg, () {
 enum extern_c_length = "extern (C)".length;
 string result;
 string loader;
 string functionPointers;

 foreach(m;__traits(allMembers, gccjit)) {
  static if (is(typeof(mixin("gccjit." ~ m)) F == function))
  {
    enum typename = typeof(mixin("gccjit." ~ m)).stringof;
    enum stypename = typename[extern_c_length .. $];
    enum rettype_end = stypename.countUntilLParen;
    enum rettype = stypename[0 .. rettype_end];
    enum paramtypes = stypename[rettype_end .. $];
    enum ftypename = rettype ~ " function " ~ paramtypes;

    functionPointers ~= ftypename ~ " " ~ m  ~ ";\n"; 
    loader ~= "    " ~ m ~ " = cast(" ~ ftypename ~  ") dlsym(lib_handle, \"" ~ m ~ "\");\n" ;
  }
 }
 return functionPointers ~ "\n" ~ loader_head ~ loader ~ loader_tail;
} ());

int countUntilLParen(string s) pure
{
   int cnt;
   while (s[cnt++] != '(') { if (cnt == cast(uint)s.length) return -1; }
   return cnt - 1;
}

void main() {}
