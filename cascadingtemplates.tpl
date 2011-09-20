/*<?php*/
/**
 * Cascading Templates
 *
 * Cascading Templates
 * @category 	plugin
 * @version 	1.01
 * @license 	BSD (http://www.opensource.org/licenses/bsd-license.php)
 * @internal	@properties &delim=Delimiter;text;.
 * @internal	@events OnLoadWebDocument 
 * @internal	@modx_category Manager and Admin
 * @author		uglydog (http://nanabit.net/)
 * @website		http://nanabit.net/modx/cascading-templates
 */

/* History  :
 *   1.01 20100622 convert docblock format (by yama)
 *   1.00 20070429 first release
 */
/* How this plugin works:
 *   When this plugin called with a dot-delimited template,  it loads the dot
 *  delimited parent-template and place the original template into it.  This
 *  works on any level of templates, so "t.outer" (containing "t.outer.inner")
 *  is merged into "t" in the next stage.
 * 
 * Example:
 *  t.outer.inner
 *  t.outer
 *  t
 *    goes...
 *  t[t.outer[t.outer.inner[*content*]]]
 */

// Settings
define (CASCADING_TEMPLATES_DELIMTER, $delim); // the delimiter
define (CASCADING_TEMPLATES_CONTENT_REPLACEMENT, '#@#content#@#'); // replace [*content*]

/* DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE DOING */

$e = &$modx->event;
switch($e->name) {
  case 'OnLoadWebDocument':
    $tbl = $modx->getFullTableName('site_templates');
    $sql = "SELECT templatename FROM $tbl WHERE $tbl.id = '".$modx->documentObject['template']."'";
    $result = $modx->db->query($sql);
    if (!$modx->db->getRecordCount($result))
      return;
    $row = $modx->db->getRow($result);
    // list up parent tempaltes 
    $parent_pieces = explode(CASCADING_TEMPLATES_DELIMTER, $row['templatename']);
    // no parent template
    if (count($parent_pieces)<=1)
      return;
    // generate below from temp.late.outer.inner
    // temp
    // temp.late
    // temp.late.outer
    $parent_templates = array();
    for ($i=0; $i<count($parent_pieces)-1; $i++)
    {
      for ($j=$i; $j<count($parent_pieces)-1; $j++) {
        if (!isset($parent_templates[$j]))
          $parent_templates[$j] = $parent_pieces[$i];
        else
          $parent_templates[$j] .= '.'.$parent_pieces[$i];
      }
    }

    // get templates 
    $templates = implode(',', array_map(create_function('$a', 'return "\'$a\'";'), $parent_templates)); 
    $sql = "SELECT content, templatename FROM $tbl WHERE $tbl.templatename";
    if (count($parent_templates)==1)
      $sql .= " = $templates";
    else
      $sql .= " in ($templates)";
    $result = $modx->db->query($sql);
    if (!$modx->db->getRecordCount($result))
      return;
    $template_name_to_content = array();
    while ($row = $modx->db->getRow($result))
      $template_name_to_content[$row['templatename']] = $row['content'];

    // apply templates
    $parent_templates = array_reverse($parent_templates);
    // prevent recursive replacement
    $modx->documentContent = str_replace('[*content*]', CASCADING_TEMPLATES_CONTENT_REPLACEMENT, $modx->documentContent);
    $push_documentObject_content = $modx->documentObject['content'];
    for ($i=0; $i<count($parent_templates); $i++) {
      if (!isset($template_name_to_content[$parent_templates[$i]]))
        continue;
      // inner template
      $modx->documentObject['content'] = $modx->documentContent;
      // merge inner template into outer template
      $modx->documentContent = $modx->parseDocumentSource($template_name_to_content[$parent_templates[$i]]);
    }
    $modx->documentObject['content'] = $push_documentObject_content;
    $modx->documentContent = str_replace(CASCADING_TEMPLATES_CONTENT_REPLACEMENT, '[*content*]', $modx->documentContent);
    return;
  default:
    return;
}
/*?>*/
