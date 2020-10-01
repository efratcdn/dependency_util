example_report_dependencies.e
  
  An example of building my own report, using the dependency util queries 

  One can use these methods as it, or modify them
  
  
  Implementing these methods:
    
  1)
  Report all the modules that module dependent_name depends on
  including indirect dependencies.
  
  report_file_dependencies(dependent_name : string, 
                           first_module   : string,
                           last_module    : string,
                           report_style   : report_style) 
  usage examle:

  report_file_dependencies("my_agent", "", "", dependencies_list );  

    
  2)
  
    report_dependencies_two_files(dependent_name : string,
                                  dependee_name  : string,
                                  report_style   : report_style)
    
  usage exmaple:
  
   sys.report_dependencies_two_files("agent", "monitor", 
                                          string_info); 
    
  3)
  
  report_dependencies(dependent_kind: element_kind,
                      dependent_pattern: string, 
                      dependee_kind: element_kind,
                      dependee_pattern: string) 
  
  usage exmaple:
  
   sys.report_dependencies(type, "pkt_s", type, "8");
   
    
<'
import e_util_dependency_util;

type report_style : [dependencies_list, string_info, details];

extend sys {
      
    // report_file_dependencies()
    // -------------------------
    // Print all modules that the module named dependent_name depends on.
    // Recursive - for each of the dependee modules, print the modules
    // they depend on.
    //
    // Level of information is according to report_style :
    //
    //   dependencies_list  : printed information is format of
    //                        "file a depends on file b" 
    //   string_info        : prints also the reason for the dependency,
    //                        in format of 
    //      <elem>, line <num> in @<mod> on <elem>, line <num> in @<mod> 
    //   details            : extract the information, so can be sent to 
    //                        external report
    //
    report_file_dependencies(dependent_name : string, 
                             first_module   : string,
                             last_module    : string,
                             report_style   : report_style) is {
        
       
        // Get the info - module_dependencies - of all modules 
        // that dependent_name depends on
        var module_dependencies_l := 
              dependencies_query::find_module_dependencies_recursively(
                  dependent_name,
                  first_module, last_module); 
        out("module_dependencies_l.size() == ", module_dependencies_l.size() );
        
        
        // remove from the list myself and the dpendency_util file
        module_dependencies_l = 
          module_dependencies_l.all(
              .get_dependent().get_name() != "example_report_dependencies" and
              .get_dependent().get_name() != "e_util_dependency_util");
      
        
        if module_dependencies_l is empty {
            out("\n\nThe module " , dependent_name, 
                " does not depend on any other module in this env");
        }; 
        
        var dependent_module_name : string;
        var modules_depending_on  : list of rf_module;
        
        // each module_dependency contain:
        //     the dependent module
        //     list of depdencee modules
        for each (one_module_dependencies) in module_dependencies_l {
            dependent_module_name = 
              one_module_dependencies.get_dependent().get_name();
            
            // call get_all_deps(), to get the list of the modules
            // dependening on
            modules_depending_on = 
              one_module_dependencies.get_all_deps().
              all(it.get_name() != "example_report_dependencies" and 
                  it.get_name() != "e_util_dependency_util");
            
            out("\n",
                dependent_module_name,
                " depends directly on ",
                 modules_depending_on.size() > 0 ? 
                  append( modules_depending_on.size(),
                          " modules:")
                  : "no module");
            
            for each (m) in  modules_depending_on {
                out("  ", m.get_name());
            };
            
            // Print more information, if required
            if (report_style != dependencies_list) {
                // Traverse the list of the modules, and for each of it -
                // get the reasons for the dependency.
                for each (one_rf_module) in  modules_depending_on {
                    
                    out("\n  ", 
                        one_module_dependencies.get_dependent().get_name(), 
                        " ", one_rf_module.get_name());
                    dependencies_query::print_all_dependencies_by_pattern(
                        module,
                        one_module_dependencies.get_dependent().get_name(),
                        module, one_rf_module.get_name(), TRUE);
   
                };
            };
        };
    }; // report_file_dependencies()
    
    // report_dependencies_two_files()
    // -----------------------------
    // Reports dependencies between the two files
    //
    // Level of information is according to report_style 
    //   string_info        : prints also the reason for the dependency,
    //                        in format of 
    //      <elem>, line <num> in @<mod> on <elem>, line <num> in @<mod> 
    //   details            : extract the information, so can be sent 
    //                        to external report
    //
    report_dependencies_two_files(dependent_name : string,
                                  dependee_name  : string,
                                  report_style   : report_style) is {
                
        var one_dependency_info      : dependency_info;
        var direct_dependency_info_l : list of direct_dependency_info;

        // Get the list of all dependencies of dependent_name and dependee_name.
        // The list will be of size of one.
        // There is one dependency_info for each pair of two elements.
        // When calling this method with wildcards - the return list
        // can contain multiple items, each representing dependencies 
        // of two modules
        var dependency_info_l : list of dependency_info;
        dependency_info_l = 
          dependencies_query::
          find_all_dependencies_by_pattern(module,
                                           dependent_name,
                                           module, dependee_name);
        
        if dependency_info_l is empty {
            out("\nThere is a limitation - we know that ", dependent_name,
                " depends on ", dependee_name, " but info is missing");
            return;
        };
        
        // As said above - the list has only one item, 
        one_dependency_info = dependency_info_l[0];  
    
        out("\n\nThe dependencies between ",
            dependent_name, " and ", dependee_name, 
            " :\n------------------------");
            
        // The dependency_info contains two elements -
        // one dependent and one dependee,
        // and a list of direct_dependency_info.
        // Traverse this list to print the reasons for the dependency
       
        direct_dependency_info_l = 
                 one_dependency_info.get_direct_dependencies();
        
        for each (one_direct_dependency_info) in direct_dependency_info_l {
            if (report_style == string_info) {
                // One liner, using the get_printed_line of dependency_element
                outf("%s depends on %s\n", 
                     one_direct_dependency_info.get_dependent().
                       get_printed_lines(),
                     one_direct_dependency_info.get_dependee().
                       get_printed_lines());
            } else {
                one_direct_dependency_info.extract_info();
            };
        };
        
    };

    
    // report_dependencies()
    //
    // Getting dependencies information, and report it
    
    report_dependencies(dependent_kind: element_kind,
                        dependent_pattern: string, 
                        dependee_kind: element_kind,
                        dependee_pattern: string) is {
        var dependency_info_l : list of dependency_info;
        
        dependency_info_l =
          dependencies_query::find_all_dependencies_by_pattern(
              dependent_kind, dependent_pattern, 
              dependee_kind, dependee_pattern);
        dependency_info_l = dependency_info_l.all(
            .get_dependee_module_name() != "e_util_dependency_util");
        for each (one_dependency_info) in dependency_info_l {
            
            //print one_dependency_info;
            for each (one_direct_dependency_info) in
              one_dependency_info.direct_dependencies {
                one_direct_dependency_info.extract_info();
            };
        };
    };
    
    
};


// Examples of how we can extract the details of the dependent and dependee
// so can write them, for example, to an excel in the desired format 


// Here we print them one by one, but instead - can write to a file, 
// or extract more info about them (using reflection, etc)
extend direct_dependency_info {
    extract_info() is {
        out();        
        
        out("dependent element : ",
            get_dependent().get_element_name() );
        out("dependee  element : ",
            get_dependee().get_element_name() );
        out("appears in lines  : ",
            str_join(location_lines.apply(append(it)), ","));
    };
   
};


'>

