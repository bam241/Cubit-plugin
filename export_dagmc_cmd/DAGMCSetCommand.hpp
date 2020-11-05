#ifndef DAGMCSetCommand_HPP
#define DAGMCSetCommand_HPP

#include "CubitCommandInterface.hpp"
#include "CubitMessageHandler.hpp"

// CGM includes
#include "RefEntity.hpp"

// MOAB includes
#include "moab/Interface.hpp"
#include "moab/GeomTopoTool.hpp"

// make_watertight includes
#include "make_watertight/MakeWatertight.hpp"

typedef std::map<RefEntity*, moab::EntityHandle> refentity_handle_map;
typedef std::map<RefEntity*, moab::EntityHandle>::iterator refentity_handle_map_itor;

/*!
 * \brief The DAGMCSetCommand class implements all the steps necessary
 * to load faceted data into a MOAB instance and export as a MOAB mesh.
 */
class DAGMCSetCommand: public CubitCommand
{
public:
  DAGMCSetCommand();
  ~DAGMCSetCommand();

  std::vector<std::string> get_syntax();
  std::vector<std::string> get_syntax_help();
  std::vector<std::string> get_help();
  bool execute(CubitCommandData &data);
  
protected:

  moab::ErrorCode parse_options(CubitCommandData &data);

private:

  moab::Interface* mdbImpl;
  moab::GeomTopoTool* myGeomTool;
  CubitMessageHandler* console;

  std::ostringstream message;

  moab::Tag geom_tag, id_tag, name_tag, category_tag, faceting_tol_tag, geometry_resabs_tag;

  int norm_tol;
  double faceting_tol;
  double len_tol;
  bool verbose_warnings;
  bool fatal_on_curves;
  bool make_watertight;
  std::string pyne_mat_lib;
  std::string hdf5_path;
  std::string hdf5;


  int failed_curve_count;
  std::vector<int> failed_curves;

  int failed_surface_count;
  std::vector<int> failed_surfaces;


};

#endif // DAGMCSetCommand_HPP
