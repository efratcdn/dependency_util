 
File name     : e_util_dependency_util.e
Title         : Dependency Util
Project       : Utilities
Created       : 2020
Description   : Static analysis of the environment, finding dependencies between
              : elements (directories, modules, types)
              :
              : See details below
              :
Notes         : Must be in lint_mode for the utility to work
              :
  
  specman -c 'config misc -lint_mode; load e_util_dependency_util.e <env files>'

              :
Prerequisites : Specman 19.09
              :
Examples      : 
        
--------------------------------------------------------------------------- 
//----------------------------------------------------------------------
//   Copyright 2020 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide

  
Description:
============

Running the utility:
===================
  
  To use this utility, you must set the following, prior to loading or
  compiling the code in which you want to find dependencies:
  
    config misc -lint_mode
or
    set_config(misc, lint_mode, TRUE)

 
  
Print dependencies:
==================
  
  Syntax:
  ------
  dependencies_query::print_all_dependencies_by_pattern( 
           dependent_kind    : element_kind, 
           dependent_pattern : string, 
           dependee_kind     : element_kind, 
           dependee_pattern  : string,
           detailed          : bool,
           first_module_name : string = "",
           last_module_name  : string = "") i)

  Description:
  -----------
  When 'detailed' is TRUE, print all the dependencies of <dependent_pattern> 
  on <dependee_pattern>.
  When 'detailed' is FALSE, print the number of dependencies of <dependent_pattern> 
  on <dependee_pattern>.
  
  
  dependent_kind    : element_kind   - one of - directory, module, type
  dependent_pattern : string         - can contain wildcards  
  dependee_kind     : element_kind   - one of - directory, module, type
  dependee_pattern  : string         - can contain wildcards 
  detailed          : bool           - when TRUE, prints detailed info of 
                                       all dependencies.
                                       when FALSE, prints count of dependencies
  first_module_name : string         - start the analysis from this module.
                                       If empty string - with first loaded/compiled
                                       module
  last_module_name  : string         - the last module to analyze.
                                       If empty string - analyze until the last 
                                       loaded/compiled module
  
  
  
  Usage example:
  -------------
  
  dependencies_query::print_all_dependencies_by_pattern(module, "soc_env", module, "ip_*", TRUE)

      print all modules start with ip_*, that soc_env.e depends on
  
  dependencies_query::print_all_dependencies_by_pattern(module, "soc_env", type, "*", TRUE)


    print all the types that soc_env.e depends on


           
  
 Query #1: get module dependencies:
 ================================= 
  
  Syntax:
  -------
  dependencies_query::find_module_dependencies_recursively(
                             module_name       : string,
                             first_module_name : string = "",
                             last_module_name  : string = "");
    
  Description:
  -----------
  
  Looks for all the modules that <moduule_name> depends on, including 
  indirect dependencies.
  
  Return a list of module_dependencies. Each module_dependencies contains 
  information of all the dependencies of <module_name>. 
  
    module_name       : string, can contain wildcards
    first_module_name : string, start the analysis from this module.
                        If empty string - with first loaded/compiled module
    last_module_name  : string, the last module to analyze.
                        If empty string - analyze until the last loaded/compiled module
  
  
  
  Usage example:
  -------------
  
   var checker_deps :=
      dependencies_query::find_module_dependencies_recursively("checker", "", "");
   for each (mod_dep) in checker_deps {
     out ( mod_dep.get_dependent().get_name(), " depends on ");
     for each in mod_dep.get_all_deps() {
        print it.get_name();
     };
   }; 
  
  
  Prints the names of all modules that checker.e depends on (the modules they
  depend on, recursively)
  

  
Query #2: get all dependencies:
============================== 
  
  Syntax:
  ------
  
  dependencies_query::find_all_dependencies_by_pattern     (
                dependent_kind    : element_kind,
                dependent_pattern : string,
                dependee_kind     : element_kind,
                dependee_pattern  : string,
                first_module_name : string,
                last_module_name  : string): list of dependency_info

  Description:
  -----------
  Looks for all the dependencies between <dependent_pattern> and <dependee_pattern>.
  
  Return a list of dependency_info. 
  Each dependency_info contains information of all dependencies between two elements.
  
    dependent_kind    : element_kind   - one of - directory, module, type
    dependent_pattern : string         - can contain wildcards  
    dependee_kind     : element_kind   - one of - directory, module, type
    dependee_pattern  : string         - can contain wildcards
    first_module_name : string         - ignore modules loaded/compiled 
                                         before this module
    last_module_name  : string         - ignore modules loaded/compiled 
                                         before this module

    Usage example:
  
       See below, under description of direct_dependency_info


dependency_info:
---------------
  
  This struct contains information of all dependencies between two elements.
  It contains information about the elements, and also a list of 
  direct_dependency_info.

    dependeny_info api:
        information about the dependent:
             get_dependent_element_name(): string    
             get_dependent_source_line(): string   
             get_dependent_container(): string is 
        information about the dependee
             det_dependee_element_name(): string 
	     get_dependee_source_line(): string 
	     get_dependee_container(): string 
	     get_dependee_module_name(): string   
        information about the dependencies:
             get_dependency_count(): int 
             get_direct_dependencies(): list of direct_dependency_info 
  
  Usage example:
  
       See below, under description of direct_dependency_info

  
direct_dependency_info:
----------------------
  
  This struct contains information about the dependencies between two elements,
  each represented by a rf_structural_element. The count is the number of times
  in which the dependent uses the dependee.
  
  direct_dependeny_info api:
       information about the dependent:
           get_dependent() : rf_structural_element   
       information about the dependee
           get_dependee() : rf_structural_element 
       information about the dependencies
           get_dependency_count(): int 

      
 Usage example:
  
  The following code prints all the types that soc_checker.e depends on

        var all_deps : list of dependency_info =
          dependencies_query::find_all_dependencies_by_pattern ( 
          module, "soc_checker", type, "*", "");
        
        for each (dep_info) in all_deps {
            
            out(dep_info.get_dependent_element_name(),
                " has ", dep_info.get_dependency_count(), " dependencies on ",
                dep_info.get_dependee_element_name(),
                " that was defined in ", dep_info.get_dependee_module_name()  );
            
            for each (direct_dep) in  dep_info.get_direct_dependencies() {
                out(" defined in lines  ",direct_dep.location_lines);
            };            
        };

<'

package e_util_dependency_util;

// structs:
//////////

// This struct contains information about the dependencies between 
// two elements, each represented by a rf_structural_element. The count is
// the number of times in which the dependent uses the dependee.
//
// rf_structural_element is the supertype of multiple structs, among them - 
// rf_named_entity, rf_parameter, rf_event_reference
//
struct direct_dependency_info like base_struct {
    dependent: rf_structural_element;
    dependee: rf_structural_element;
    location_lines: list of int;
    location_modules: list of rf_module;
    
    get_dependent() : rf_structural_element is {
        result = dependent;
    };
    
    get_dependee() : rf_structural_element is {
        result = dependee;
    };
    
    get_dependency_count(): int is {
        result = location_lines.size();
        assert result == location_modules.size();
    };
};

//  This struct contains information of all dependencies between two elements. 
// It contains information about the elements, and also a list of
// direct_dependency_info.
//
struct dependency_info like base_struct {
    main_dependent: dependency_element;
    main_dependee: dependency_element;
    direct_dependencies: list of direct_dependency_info;
    
    get_dependent_element_name(): string is {
        return main_dependent.get_element_name();
    };
    
    get_dependent_source_line(): string is {
        return main_dependent.get_element_source_line();
    };
    
    get_dependent_container(): string is {
        return main_dependent.get_element_container();
    };
    
    get_dependee_element_name(): string is {
        return main_dependee.get_element_name();
    };
    
    get_dependee_source_line(): string is {
        return main_dependee.get_element_source_line();
    };
    
    get_dependee_container(): string is {
        return main_dependee.get_element_container();
    };
    
    get_dependee_module_name(): string is {    
        return main_dependee.get_element_module_name();
    };
    
    get_dependency_count(): int is {
        return direct_dependencies.sum(it.get_dependency_count());
    };
    
    get_direct_dependencies(): list of direct_dependency_info is {
        return direct_dependencies;
    };
};

struct module_elements {
    module_name : string;
    elements    : list of rf_structural_element;
};

extend rf_structural_element {
    get_element_name(): string is empty;
    get_element_source_line(): string is empty;
    get_element_module_name(): string is empty;
    get_element_container(): string is empty;
};

extend rf_named_entity {
    get_element_name(): string is {
        return get_name();
    };
    
    get_element_source_line(): string is {
        return appendf("line %d in %s.e", get_declaration_source_line_num(),
                       get_declaration_module().get_name());
    };
    
    get_element_module_name(): string is {
        return get_declaration_module().get_name();
    };
};

extend rf_definition_element {
    get_element_name(): string is {
        return get_defined_entity().get_name();
    };
    
    get_element_source_line(): string is {
        return appendf("line %d in %s.e", get_source_line_num(),
                       get_module().get_name());
    };
    
    get_element_module_name(): string is {
        return get_module().get_name();
    };
};

extend rf_module {
    get_element_name(): string is {
        return append(get_name(), ".e");
    };
    
    get_element_container(): string is {
        var full_name: string = get_full_file_name();
        return str_sub(full_name, 0, 
                       str_len(full_name)-str_len(get_element_name()));
    };
};

interface dependency_element {
    get_all_contained_elements(include_extensions : bool, 
                               with_entities: bool): 
                   list of rf_structural_element;
    
    get_element_name(): string;
    get_element_source_line(): string;
    get_element_module_name(): string;
    get_element_container(): string;
    
    get_printed_lines(): list of string;
};

struct module_dependencies like base_struct {
    the_module: rf_module;
    all_deps: list (key: it) of rf_module;
    
    get_dependent() : rf_module is {
        result = the_module;
    };
    
    get_all_deps() : list of rf_module is {
        for each in all_deps {
            result.add(it);
        };
    };
};

type element_kind: [ directory, module, type ];

// Queries:
//////////

struct dependencies_query like base_struct {
    main_dependents: list of dependency_element;
    main_dependees: list of dependency_element;
    interesting_modules: list (key: it) of rf_module;

    curr_main_dependent: dependency_element;
    curr_main_dependee: dependency_element;
    curr_dependents: list of rf_structural_element;
    curr_dependees: list of rf_structural_element;
    
    found_dependencies: list of dependency_info;

    all_interesting : bool;
    
    
    assign_interesting_modules(first_module_name: string, 
                               last_module_name: string) is {
        
         if first_module_name != "" or last_module_name != "" then {
             var all_modules: list of rf_module =
               rf_manager.get_user_modules();
             var first_module: rf_module;
             var last_module: rf_module = all_modules.top();
             if first_module_name != "" then {
                 first_module =
                   rf_manager.get_module_by_name(first_module_name);
             };
             if first_module == NULL then {
                 first_module = all_modules.top0();
             };
             if last_module_name != "" then {
                 last_module = 
                   rf_manager.get_module_by_name(last_module_name);
             };
             if last_module == NULL then {
                 last_module = all_modules.top();
             };
             var add_module: bool = FALSE;
             for each (module) in all_modules do {
                 if not add_module and module == first_module then {
                     add_module = TRUE;
                 };
                 if add_module then {
                     interesting_modules.add(module);
                 };
                 if module == last_module then {
                     break;
                 };
             };
         };
    };
    
    ctor(main_dependents: list of dependency_element, 
         main_dependees: list of dependency_element,
         first_module_name: string, last_module_name: string) is {
        
        me.main_dependents = main_dependents;
        me.main_dependees = main_dependees;  
        
        if not started_with_interesting() {
            assign_interesting_modules( first_module_name, last_module_name);
        };
    };
    
    is_interesting_module(module: rf_module): bool is {
        return module == NULL or
          interesting_modules.is_empty() or
          interesting_modules.key_exists(module);
    };
    
    add_direct_dependency(dependent: rf_structural_element,
                          dependee: rf_named_entity, 
                          source_line_num: int, source_module: rf_module,
                          check: bool) is {
        
        if check and ((dependent not in curr_dependents) or 
                      (dependee not in curr_dependees)) then {
            return;
        };
        
        assert is_interesting_module(source_module);
        if not dependee.get_definition_elements().
          has(is_interesting_module(it.get_module())) then {
            return;
        };

        var dep: dependency_info = 
          found_dependencies.first(it.main_dependent == curr_main_dependent and
                                   it.main_dependee == curr_main_dependee);
        if dep == NULL then {
            dep = new with {
                it.main_dependent = curr_main_dependent;
                it.main_dependee = curr_main_dependee;
            };
            found_dependencies.add(dep);
        };
        
        var direct_dep: direct_dependency_info =
          dep.direct_dependencies.first(it.dependent == dependent and
                                        it.dependee == dependee);
        if direct_dep == NULL then {
            direct_dep = new with {
                it.dependent = dependent;
                it.dependee = dependee;
            };
            dep.direct_dependencies.add(direct_dep);
        };
        direct_dep.location_lines.add(source_line_num);
        direct_dep.location_modules.add(source_module);
    };

    add_direct_dependency_on_type(dependent: rf_structural_element,
                                  dependee: rf_type, source_line_num: int,
                                  source_module: rf_module, check: bool) is {
        for each in dependee.get_explicit_entities() do {
            add_direct_dependency(dependent, it, source_line_num, source_module, check);
        };
    };
        
    static !module_elements_l : list of module_elements;
    add_module_elements(new_me : module_elements) is {
        module_elements_l.add(new_me);
    };
    get_module_elements(m_name: string ): module_elements is {
        result = module_elements_l.first(.module_name == m_name);
    };
      
    execute(): list of dependency_info is {
        found_dependencies.clear();

        var all_dependents: list of rf_structural_element;
        var all_dependees: list of rf_structural_element;
        var module_elements : module_elements;
        
        for each in main_dependents do {
            curr_main_dependent = it;
            curr_dependents =
              curr_main_dependent.get_all_contained_elements(TRUE, FALSE);
            for each in main_dependees do {
                curr_main_dependee = it;
                if curr_main_dependent != curr_main_dependee then {
                                        
                    if curr_main_dependee is a rf_module {
                        module_elements = 
                          get_module_elements(curr_main_dependee.as_a(rf_module).get_name());
                        if module_elements == NULL {
                            module_elements = new with {
                                .module_name = 
                                  curr_main_dependee.as_a(rf_module).get_name()};
                            module_elements.elements = 
                              curr_main_dependee.get_all_contained_elements(FALSE, TRUE);
                            add_module_elements(module_elements);
                        };
                        curr_dependees = module_elements.elements;
                    } else {
                        // not a module
                        curr_dependees = 
                          curr_main_dependee.get_all_contained_elements(FALSE, 
                                                                        TRUE);

                    };

                    for each (elem) in curr_dependents do {
                        elem.find_dependencies(me, curr_dependees);
                    };
                };
            };
        };
        
        return found_dependencies;
    };

    static find_all_dependencies(dependent: list of dependency_element,
                                 dependees: list of dependency_element,
                                 first_module_name: string = "",
                                 last_module_name: string = ""):
                                           list of dependency_info is {
        var query: dependencies_query = new;
        query.ctor(dependent, dependees, first_module_name, last_module_name);
        return query.execute();
    };

    static add_elements_by_kind_and_pattern_to_list(
                          kind: element_kind,
                          pattern: string, 
                          the_list: list of dependency_element) is {
        case kind {
            directory: {
                for each (dir_name) in output_from(appendf("ls -d %s",
                                                           pattern)) do {
                    if files.file_is_dir(dir_name) then {
                        var dir_elem: directory_element = new with {
                            it.full_dir_name = dir_name;
                        };
                        the_list.add(dir_elem);
                    };
                };
            };
            
            module: {
                var module: rf_module = rf_manager.get_module_by_name(pattern);
                if module != NULL then {
                    the_list.add(module);
                } else if pattern ~ "/\*/" then {
                    for each (module) in rf_manager.get_user_modules() do {
                        if (module.get_name() ~ pattern) or
                          (append(module.get_name(), ".e") ~ pattern) then {
                            the_list.add(module);
                        };
                    };
                };
            };
            
            type: {
                var rft: rf_type = rf_manager.get_type_by_name(pattern);
                if rft != NULL then {
                    the_list.add(rft);
                } else if pattern ~ "/\*/" then {
                    for each (rft) in rf_manager.get_user_types() do {
                        if rft.get_name() ~ pattern then {
                            the_list.add(rft);
                        };
                    };
                };
            };
        };
    };
    
    // find_all_dependencies_by_pattern() 
    //
    //  Looks for all the dependencies between <dependent_pattern> and <dependee_pattern>.
    //
    // Return a list of dependency_info. 
    // Each dependency_info contains information of all dependencies between two elements.
    //
    static find_all_dependencies_by_pattern(dependent_kind: element_kind,
                                            dependent_pattern: string,
                                            dependee_kind: element_kind,
                                            dependee_pattern: string, 
                                            first_module_name: string = "",
                                            last_module_name: string = ""): 
                                                               list of dependency_info is {
        var main_dependents: list of dependency_element;
        add_elements_by_kind_and_pattern_to_list(dependent_kind, dependent_pattern,
                                                 main_dependents);

        var main_dependees: list of dependency_element;
        add_elements_by_kind_and_pattern_to_list(dependee_kind, dependee_pattern,
                                                 main_dependees);

        var query: dependencies_query = new;
        query.ctor(main_dependents, main_dependees, first_module_name, last_module_name);
        return query.execute();
    };
    

    // Return the list of modules within the first_module_name - last_module_name
    static get_interesting_modules(first_module_name: string = "",
                                   last_module_name: string = "") : list of rf_module is {
        var all_modules  : list of rf_module = rf_manager.get_user_modules();
        var first_module : rf_module;
        var last_module  : rf_module = all_modules.top();
        
        if first_module_name == "" and
          last_module_name == "" then {
            return all_modules;
        };
          
        if first_module_name != "" then {
            first_module = rf_manager.get_module_by_name(first_module_name);
        };
        if first_module == NULL then {
            first_module = all_modules.top0();
        };
        if last_module_name != "" then {
            last_module = rf_manager.get_module_by_name(last_module_name);
        };
        if last_module == NULL then {
            last_module = all_modules.top();
        };
        var add_module: bool = FALSE;
        for each (module) in all_modules do {
            if not add_module and module == first_module then {
                add_module = TRUE;
            };
            if add_module then {
                result.add(module);
            };
            if module == last_module then {
                break;
            };
        };
    };
    

    static started_with_interesting : bool = FALSE; 
    static set_interesting() is {
        started_with_interesting = TRUE;
    };
    static started_with_interesting() : bool is {
        return started_with_interesting;
    };
    
    // find_module_dependencies_recursively()
    //
    //  Looks for all the modules that <moduule_name> depends on, including 
    // indirect dependencies.
    //
    // Return a list of module_dependencies. Each module_dependencies contains 
    // information of all the dependencies of <module_name>. 
    
    static find_module_dependencies_recursively(
        dependent_module_pattern: string,
        first_module_name: string = "", 
        last_module_name: string = ""): 
      list (key: the_module) of module_dependencies is {
      
        var all_modules: list of rf_module =
          get_interesting_modules(first_module_name, last_module_name);
        set_interesting();
        
        var all_modules_as_elements: list of dependency_element =
          all_modules.as_a(list of dependency_element);
        
        var module: rf_module = 
          rf_manager.get_module_by_name(dependent_module_pattern);
        if module != NULL then {
            result.add(new with {
                it.the_module = module;
            });
        } else if dependent_module_pattern ~ "/\*/" then {
            for each (module) in all_modules do {
                if (module.get_name() ~ dependent_module_pattern) or
                  (append(module.get_name(), ".e") ~ dependent_module_pattern) then {
                    result.add(new with {
                        it.the_module = module;
                    });
                };
            };
        };

        var all_deps : list of dependency_info ;
        
        for each (rec_dep) in result do {
           
            var tmp_list: list of dependency_element;
            tmp_list.add(rec_dep.the_module);
            all_deps =
              find_all_dependencies(tmp_list,
                                    all_modules_as_elements,
                                    first_module_name, last_module_name) ;
            for each (dep) in all_deps do {
                var other_module: rf_module = dep.main_dependee.as_a(rf_module);
                assert other_module != NULL;
                rec_dep.all_deps.add(other_module);
                if not result.key_exists(other_module) then {
                    result.add(new with {
                        it.the_module = other_module;
                    });
                };
            };
        };
    };

    static print_dependencies(deps: list of dependency_info, detailed: bool) is {
        if deps.is_empty() then {
            out("No dependencies were found");
            return;
        };
        var direct_deps: list of direct_dependency_info;
        if detailed then {
            direct_deps = deps.apply(it.get_direct_dependencies());
        };
        
        var printed1: list of string = detailed ?
            direct_deps.apply(it.dependent.get_printed_lines()[0]) :
            deps.apply(it.main_dependent.get_printed_lines()[0]);
        var width1: int = str_len(printed1.max(str_len(it)));
        for each in printed1 do {
            printed1[index] = str_pad(it, width1);
        };
        var title1: string = str_pad("Dependent element", width1);
        
        var printed2: list of string = detailed ?
            direct_deps.apply(it.dependee.get_printed_lines()[0]) :
            deps.apply(it.main_dependent.get_printed_lines()[0]);
        var width2: int = str_len(printed2.max(str_len(it)));
        for each in printed2 do {
            printed2[index] = str_pad(it, width2);
        };
        var title2: string = str_pad("Dependee", width2);
        
        set_config(print, line_size, width1+width2+15) {
            if detailed then {
                report direct_deps,
                {appendf("%s  %s   Count", title1, title2);
                 "------------------------------------------------------------------------------------";
                    "%s   %s   %d"},
                    printed1[index],
                    printed2[index],
                    it.get_dependency_count();
            } else {
                report deps,
                {appendf("%s   %s   Count", title1, title2);
                    "------------------------------------------------------------------------------------";
                    "%s   %s   %d"},
                    printed1[index],
                    printed2[index],
                    it.get_dependency_count();
            };
        };
    };
    
    static print_all_dependencies(dependent: list of dependency_element,
                                  dependees: list of dependency_element, 
                                  detailed: bool,
                                  first_module_name: string = "",
                                  last_module_name: string = "") is {
        var all_deps: list of dependency_info = 
          find_all_dependencies(dependent, dependees,
                                first_module_name, last_module_name);
        print_dependencies(all_deps, detailed);
    };

    // print_all_dependencies_by_pattern()
    //
    // When 'detailed' is TRUE, print all the dependencies of <dependent_pattern> 
    // on <dependee_pattern>.
    // When 'detailed' is FALSE, print the number of dependencies of <dependent_pattern> 
    // on <dependee_pattern>.
    //
    static print_all_dependencies_by_pattern(dependent_kind: element_kind,
                                             dependent_pattern: string, 
                                             dependee_kind: element_kind, 
                                             dependee_pattern: string, 
                                             detailed: bool,
                                             first_module_name: string = "",
                                             last_module_name: string = "") is {
        var all_deps: list of dependency_info = 
          find_all_dependencies_by_pattern(dependent_kind, dependent_pattern, 
                                           dependee_kind, dependee_pattern, 
                                           first_module_name, last_module_name);
        print_dependencies(all_deps, detailed);
    };
};

struct directory_element like base_struct implementing dependency_element {
    full_dir_name: string;

    get_dir_name(): string is {
        var parts: list of string = str_split(full_dir_name, "/");
        if not parts.is_empty() {
            result = parts.pop();
        };
        if result == "" and not parts.is_empty() {
            result = parts.top();
        };
    };
    
    get_all_contained_elements(include_extensions : bool,
                               with_entities: bool): list of rf_structural_element is {
        for each (module) in rf_manager.get_user_modules() do {
            if module.get_full_file_name() ~ appendf("/^%s/", full_dir_name) then {
                result.add(module.get_all_contained_elements(include_extensions,
                                                             with_entities));
            };
        };
    };
    
    get_element_name(): string is {
        return full_dir_name;
    };
    
    get_element_source_line(): string is empty;
    get_element_module_name(): string is empty;
    
    get_element_container(): string is {
        return str_sub(full_dir_name, 0, str_len(full_dir_name)-str_len(get_dir_name()));
    };
    
    get_printed_lines(): list of string is {
        result.add(append("directory '", full_dir_name, "'"));
    };
};

extend rf_structural_element implementing dependency_element {
    find_dependencies(query: dependencies_query,
                      dependees: list of rf_structural_element) is empty;
    
    get_direct_contained_elements(): list of rf_structural_element is empty;
    
    
    get_all_contained_elements(include_extensions : bool,
                               with_entities: bool): list of rf_structural_element is {
                
        var add_me : bool = FALSE; 
        if include_extensions {
            add_me = TRUE;
        } else {
            if me is a rf_definition_element (rde) {
                if me == rde.get_defined_entity().get_declaration() {
                    add_me = TRUE;
                };
            } else {
                if me is a rf_enum_item (ret) {
                    if ret.get_declaration().get_module() !=
                      ret.get_defining_type().get_declaration().get_module() {
                        add_me = TRUE;
                    };
                } else {
                    add_me = TRUE;
                };
            };
        };
        
        
        if add_me {
            result.add(me);
            if with_entities and me is a rf_definition_element (rde) {
                result.add(rde.get_defined_entity());
            };
        };
                
        for each in get_direct_contained_elements() do {
            result.add(it.get_all_contained_elements(include_extensions, with_entities));
        };
    };
};

extend rf_named_entity {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element, 
                                 def_element: rf_definition_element) is empty;

    find_dependencies(query: dependencies_query, 
                      dependees: list of rf_structural_element) is {
        
       
        if query.is_interesting_module(me.get_declaration_module()) then {
            find_dependencies_for_entity(query, 
                                         dependees, me, me.get_declaration());
        };
        for each (elem) in get_definition_elements() do {

            var m: rf_module = elem.get_module();
            if m.is_user_module() and 
              not m.is_enc_invisible() and
              query.is_interesting_module(m) then {
                elem.find_dependencies_for_element(query, dependees, me);
            };
        };
    };
};

extend rf_definition_element {
    find_dependencies_for_element(query: dependencies_query, 
                                  dependees: list of rf_structural_element,
                                  queried_element: rf_structural_element) is {
        for each (ref) in lint_manager.get_all_entity_references_in_context(me) do {
            var entity: rf_named_entity = ref.get_entity();
            if entity in dependees then {
                query.add_direct_dependency(queried_element, entity, 
                                            ref.get_source_line_num(),
                                            ref.get_source_module(), FALSE);
            };
        };
    };
    
    find_dependencies(query: dependencies_query,
                      dependees: list of rf_structural_element) is {
        if query.is_interesting_module(me.get_module()) then {
            find_dependencies_for_element(query, dependees, me);
            get_defined_entity().find_dependencies_for_entity(query, dependees, me, me);
        };
    };
};

// Modules

struct entity_references_per_module like base_struct {
    module: rf_module;
    entity_references: list of entity_reference;
};

extend lint_manager {
    entity_references_per_module_map: list (key: module) of entity_references_per_module;
};

extend rf_module {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_type_layers());
    };
    
    find_dependencies(query: dependencies_query, 
                      dependees: list of rf_structural_element) is {
                
        if not query.is_interesting_module(me) then {
            return;
        };
        var entity_references_entry: entity_references_per_module =
          lint_manager.entity_references_per_module_map.key(me);
        if entity_references_entry == NULL then {
            entity_references_entry = new with {
                .module = me;
                .entity_references = lint_manager.get_all_entity_references({}, "", get_name());
            };
            lint_manager.entity_references_per_module_map.add(entity_references_entry);
        };
        for each (ref) in entity_references_entry.entity_references do {
            if ref.get_context() == NULL then {
                var entity: rf_named_entity = ref.get_entity();
                if entity in dependees then {                    
                    if entity is a rf_type (rft) then {
                        query.add_direct_dependency_on_type(me,
                                                            rft, ref.get_source_line_num(),
                                                            ref.get_source_module(), FALSE);
                    } else {
                        query.add_direct_dependency(me, entity,
                                                    ref.get_source_line_num(),
                                                    ref.get_source_module(), FALSE);
                    };
                };
            };
        };
    };
};

// Types

extend rf_type {
    get_explicit_entities(): list of rf_named_entity is {
        result.add(me);
    };
};

extend rf_enum_layer {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_added_items());
    };
};

extend rf_enum {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_items());
    };
};

struct method_layers_per_struct_layer like base_struct {
    struct_layer: rf_struct_layer;
    method_layers: list of rf_method_layer;
};

extend lint_manager {
    method_layers_per_struct_layer_map: list (key: struct_layer) 
      of method_layers_per_struct_layer;
};

extend rf_struct_layer {
    get_method_layers_efficiently(): list of rf_method_layer is {
        var method_layers_entry: method_layers_per_struct_layer = 
          lint_manager.method_layers_per_struct_layer_map.key(me);
        if method_layers_entry == NULL then {
            method_layers_entry = new with {
                .struct_layer = me;
                .method_layers = get_method_layers();
            };
            lint_manager.method_layers_per_struct_layer_map.add(method_layers_entry);
        };
        return method_layers_entry.method_layers;
    };
    
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_field_declarations());
        result.add(get_method_layers_efficiently());
        result.add(get_event_layers());
        result.add(get_expect_layers());
        result.add(get_constraint_layers());
        result.add(get_cover_group_layers());
    };
    
    find_dependencies_for_element(query: dependencies_query, 
                                  dependees: list of rf_structural_element, 
                                  queried_element: rf_structural_element) is also {
        for each (intf) in get_added_interfaces() do {
            query.add_direct_dependency_on_type(queried_element, 
                                                intf, get_source_line_num(), 
                                                get_module(), TRUE);
        };
    };
};

extend rf_struct {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_fields());
        result.add(get_methods());
        result.add(get_events());
        result.add(get_expects());
        result.add(get_constraints());
        result.add(get_cover_groups());
    };
};

extend rf_like_struct {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        query.add_direct_dependency_on_type(queried_element,
                                            get_supertype(), 
                                            def_element.get_source_line_num(),
                                            def_element.get_module(), TRUE);
    };
};

extend rf_when_subtype {
    get_explicit_entities(): list of rf_named_entity is only {
        result.add(get_when_base());
        var det_values: list of int = get_determinant_values();
        for each (f) in get_determinant_fields() do {
            result.add(f);
            if f.get_type() is a rf_enum (rfe) then {
                result.add(rfe.get_item_by_value(det_values[index]));
            };
        };
    };
};

extend rf_interface {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element, 
                                 def_element: rf_definition_element) is also {
        for each (intf) in get_base_interfaces() do {
            query.add_direct_dependency_on_type(queried_element, intf, 
                                                def_element.get_source_line_num(), 
                                                def_element.get_module(), TRUE);
        };
    };
    
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_declared_methods());
    };
};

extend rf_bfm_sequence {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element, 
                                 queried_element: rf_structural_element, 
                                 def_element: rf_definition_element) is also {
        query.add_direct_dependency_on_type(queried_element, 
                                            get_item_struct(),
                                            def_element.get_source_line_num(),
                                            def_element.get_module(), TRUE);
    };
};

extend rf_template_instance {
    get_explicit_entities(): list of rf_named_entity is only {
        result.add(get_template());
        for each rf_type_template_instance_parameter (param) in get_parameters() do {
            result.add(param.get_type().get_explicit_entities());
        };
    };
};

extend rf_template_interface_instance {
    get_explicit_entities(): list of rf_named_entity is only {
        result.add(get_template());
        for each rf_type_template_instance_parameter (param) in get_parameters() do {
            result.add(param.get_type().get_explicit_entities());
        };
    };
};

extend rf_template_numeric_instance {
    get_explicit_entities(): list of rf_named_entity is only {
        result.add(get_template());
        for each rf_type_template_instance_parameter (param) in get_parameters() do {
            result.add(param.get_type().get_explicit_entities());
        };
    };
};

extend rf_list {
    get_explicit_entities(): list of rf_named_entity is only {
        result.add(get_element_type().get_explicit_entities());
    };
};

extend rf_keyed_list {
    get_explicit_entities(): list of rf_named_entity is also {
        var f: rf_field = get_key_field();
        if f != NULL then {
            result.add(f);
        };
    };
};

extend rf_port {
    get_explicit_entities(): list of rf_named_entity is only {
        var elem_type: rf_type = get_element_type();
        if elem_type != NULL then {
            result.add(get_element_type().get_explicit_entities());
        };
    };
};

extend rf_custom_numeric {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        query.add_direct_dependency_on_type(queried_element,
                                            get_implementing_struct(),
                                            def_element.get_source_line_num(),
                                            def_element.get_module(), TRUE);
    };
};

extend rf_template_type {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        for each rf_value_template_parameter (param) in get_parameters() do {
            query.add_direct_dependency_on_type(queried_element,
                                                param.get_type(), 
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
    };
};

extend rf_template {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        var supertype: rf_like_struct = get_supertype();
        if supertype != NULL then {
            query.add_direct_dependency_on_type(queried_element, supertype,
                                                def_element.get_source_line_num(), 
                                                def_element.get_module(), TRUE);
        };
    };
};

// Struct members

extend rf_field {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        query.add_direct_dependency_on_type(queried_element, get_type(),
                                            def_element.get_source_line_num(),
                                            def_element.get_module(), TRUE);
    };
};

extend rf_method {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element, 
                                 queried_element: rf_structural_element, 
                                 def_element: rf_definition_element) is also {
        for each (param) in get_parameters() do {
            query.add_direct_dependency_on_type(queried_element, param.get_type(),
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
        
        var result_type: rf_type = get_result_type();
        if result_type != NULL then {
            query.add_direct_dependency_on_type(queried_element, result_type,
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
    };
};

extend rf_interface_method {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element, 
                                 def_element: rf_definition_element) is also {
        for each (param) in get_parameters() do {
            query.add_direct_dependency_on_type(queried_element, param.get_type(),
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
        
        var result_type: rf_type = get_result_type();
        if result_type != NULL then {
            query.add_direct_dependency_on_type(queried_element, result_type,
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
    };
};

extend rf_routine {
    find_dependencies_for_entity(query: dependencies_query,
                                 dependees: list of rf_structural_element, 
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        for each (param) in get_parameters() do {
            query.add_direct_dependency_on_type(queried_element, param.get_type(), 
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
        
        var result_type: rf_type = get_result_type();
        if result_type != NULL then {
            query.add_direct_dependency_on_type(queried_element, result_type, 
                                                def_element.get_source_line_num(),
                                                def_element.get_module(), TRUE);
        };
    };
};

extend rf_cover_group_layer {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_item_layers());
    };
};

extend rf_cover_group {
    get_direct_contained_elements(): list of rf_structural_element is also {
        result.add(get_all_items());
    };
};

extend rf_simple_cover_item {
    find_dependencies_for_entity(query: dependencies_query, 
                                 dependees: list of rf_structural_element,
                                 queried_element: rf_structural_element,
                                 def_element: rf_definition_element) is also {
        query.add_direct_dependency_on_type(queried_element, get_type(), 
                                            def_element.get_source_line_num(),
                                            def_element.get_module(), TRUE);
    };
};

'>