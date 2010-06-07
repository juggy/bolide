module NavigationHelper
  
  # Override to provide the top navigation of your app
  def estimation_navigation
    tabs do
      tab "Estimations", estimations_url, :highlight => (params[:controller] == 'estimations')
      tab "Tableaux Modèles", tableau_templates_url, :highlight => (params[:controller] == 'tableau_templates')
      #tab "Catalog", product_catalog_url(:action => 'edit'), :highlight => (params[:controller] == 'product_catalog')
      tab "Type de materiaux", material_categories_url, :highlight => (params[:controller] == 'material_categories')
      tab "Materiaux", materials_url, :highlight => (params[:controller] == 'materials')
      haml_tag :li do
        haml_concat "&nbsp;"
      end
      tab "Retour", "/"
    end
  end
  
end