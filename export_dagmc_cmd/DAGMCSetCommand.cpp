#include "DAGMCSetCommand.hpp"
#include "CubitInterface.hpp"

// CGM includes
#include "GeometryQueryTool.hpp"
#include "ModelQueryEngine.hpp"
#include "GMem.hpp"

#include "RefEntityName.hpp"

#include "Body.hpp"
#include "Surface.hpp"
#include "Curve.hpp"

#include "RefGroup.hpp"
#include "RefFace.hpp"
#include "RefEdge.hpp"
#include "RefVertex.hpp"

#include "SenseEntity.hpp"



#define CHK_MB_ERR_RET(A,B)  if (moab::MB_SUCCESS != (B)) { \
  message << (A) << (B) << std::endl;                                   \
  CubitInterface::get_cubit_message_handler()->print_message(message.str().c_str()); \
  return false;                                                         \
  }

#define CHK_MB_ERR_RET_MB(A,B)  if (moab::MB_SUCCESS != (B)) { \
  message << (A) << (B) << std::endl;                                   \
  return rval;                                                         \
  }

DAGMCSetCommand::DAGMCSetCommand()
{
  // set default values
  norm_tol = 5;
  faceting_tol = 1e-3;
  len_tol = 0.0;
  verbose_warnings = false;
  fatal_on_curves = false;

  pyne_mat_lib = "";
  hdf5_path = "/materials";

  CubitMessageHandler *console = CubitInterface::get_cubit_message_handler();
  if (console) {
    std::ostringstream load_message;
    load_message.str("");
    load_message << "-- DAGMC export command available." << std::endl;
    CubitInterface::get_cubit_message_handler()->print_error(load_message.str().c_str());
  }
}

DAGMCSetCommand::~DAGMCSetCommand()
{}

std::vector<std::string> DAGMCSetCommand::get_syntax()
{
  // Define the syntax for the command. Note the syntax is a modified BNF
  // format. Full documentation on the command specification syntax can be
  // found in the documentation.
  std::string syntax =
      "export dagmc "
      "<string:label='filename',help='<filename>'> "
      "[faceting_tolerance <value:label='faceting_tolerance',help='<faceting tolerance>'>] "
      "[length_tolerance <value:label='length_tolerance',help='<length tolerance>'>] "
      "[normal_tolerance <value:label='normal_tolerance',help='<normal tolerance>'>] "
      "[make_watertight]"
      "[pyne_mat_lib <string:label='pyne_mat_lib',help='<pyne_mat_lib>'>]"
      "[hdf5_path <string:label='hdf5_path',help='<hdf5_path>'>]"
      "[verbose] [fatal_on_curves]";

  std::vector<std::string> syntax_list;
  syntax_list.push_back(syntax);

  return syntax_list;
}

std::vector<std::string> DAGMCSetCommand::get_syntax_help()
{
  std::vector<std::string> help;
  return help;
}

std::vector<std::string> DAGMCSetCommand::get_help()
{
  std::vector<std::string> help;
  return help;
}

bool DAGMCSetCommand::execute(CubitCommandData &data)
{

  
  
  return result;
}

moab::ErrorCode DAGMCSetCommand::parse_options(CubitCommandData &data, moab::EntityHandle* file_set)
{
  moab::ErrorCode rval;

  // read parsed command for faceting tolerance
  data.get_value("faceting_tolerance",faceting_tol);
  message << "Setting faceting tolerance to " << faceting_tol << std::endl;

  // read parsed command for length tolerance
  data.get_value("length_tolerance",len_tol);
  message << "Setting length tolerance to " << len_tol << std::endl;

  // Always tag with the faceting_tol and geometry absolute resolution
  // If file_set is defined, use that, otherwise (file_set == NULL) tag the interface  
  moab::EntityHandle set = file_set ? *file_set : 0;
  rval = mdbImpl->tag_set_data(faceting_tol_tag, &set, 1, &faceting_tol);
  CHK_MB_ERR_RET_MB("Error setting faceting tolerance tag",rval);

  // read parsed command for normal tolerance
  data.get_value("normal_tolerance",norm_tol);
  message << "Setting normal tolerance to " << norm_tol << std::endl;

  rval = mdbImpl->tag_set_data(geometry_resabs_tag, &set, 1, &GEOMETRY_RESABS);
  CHK_MB_ERR_RET_MB("Error setting geometry_resabs_tag",rval);
  
  // read parsed command for verbosity
  verbose_warnings = data.find_keyword("verbose");
  fatal_on_curves = data.find_keyword("fatal_on_curves");
  make_watertight = data.find_keyword("make_watertight");

  // read parsed command for normal tolerance
  data.get_string("pyne_mat_lib", pyne_mat_lib);
  if (pyne_mat_lib != "") {
    message << "Looking for the PyNE material Lib in " << pyne_mat_lib << std::endl;
    data.get_string("hdf5_path",hdf5);
    if (hdf5 != "") {
      hdf5_path = hdf5;
    } else {
      message << "hdf5 path not provided, falling back on default path"
        << std::endl;
    }

    message << "hdf5 path set to " << hdf5 << std::endl;
  }
  else {
    message
        << "No Material Library set, material assignments will not be processed"
        << std::endl;
  }

  if (verbose_warnings && fatal_on_curves)
    message << "This export will fail if curves fail to facet" << std::endl;

  return rval;
}
