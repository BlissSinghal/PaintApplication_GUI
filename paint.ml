(** The main paint application *)

;; open Gctx
;; open Widget

(******************************************)
(**    SHAPES, MODES, and PROGRAM STATE   *)
(******************************************)

(** A location in the paint_canvas widget *)
type point = position  (* from Gctx *)

(** The shapes that are visible in the paint canvas -- these make up the
    picture that the user has drawn, as well as any other "visible" elements
    that must show up in the canvas area (e.g. a "selection rectangle"). At
    the start of the homework, the only available shape is a line.  *)
(* TODO: You will modify this definition in Tasks 3, 4, 5 and maybe 6. *)
type shape = 
  | Line of {color: color; width: int; p1: point; p2: point}
  | Points of {color: Gctx.color; width: int; points: point list }
  | Ellipse of {color: Gctx.color; width: int; p1: point; rx: int; ry: int}
  

(** These are the possible interaction modes that the paint program might be
    in. Some interactions require two modes. For example, the GUI might
    recognize the first mouse click as starting a line and a second mouse
    click as finishing the line.

    To start out, there are only two modes:

      - LineStartMode means the paint program is waiting for the user to make
        the first click to start a line.

      - LineEndMode means that the paint program is waiting for the user's
        second click. The point associated with this mode stores the location
        of the user's first mouse click.  *)
(* TODO: You will need to modify this type in Tasks 3 and 4, and maybe 6. *)
type mode = 
  | LineStartMode
  | LineEndMode of point
  | PointMode
  | EllipseMode

(** The state of the paint program. *)
type state = {
  (** The sequence of all shapes drawn by the user, in order from
      least recent (the head) to most recent (the tail). *)
  shapes : shape Deque.deque;
  

  (** The input mode the Paint program is in. *)
  mutable mode : mode;

  (** The currently selected pen color. *)
  mutable color : color;

  (* TODO: You will need to add new state for Tasks 2, 5, and *)
  (* possibly 6 *) 
  mutable preview: shape option;

  mutable line_width: int; 
}

(** Initial values of the program state. *)
let paint : state = {
  shapes = Deque.create ();
  mode = LineStartMode;
  color = black;
  (* TODO: You will need to add new state for Tasks 2, 5, and maybe 6 *)
  preview = None;
  (*adding a state for line_width*)
  line_width = 1
}



(** This function creates a graphics context with the appropriate
    pen color. *)
(* TODO: Your will need to modify this function in Task 5 *)
let with_params (g: gctx) (c: color) (line_thickness: int) : gctx =
  let g1 = with_color g c in
  let g2 = with_width g1 line_thickness in
  g2


(*********************************)
(**    MAIN CANVAS REPAINTING    *)
(*********************************)

(** The paint_canvas repaint function.

    This function iterates through all the drawn shapes (in order of least
    recent to most recent so that they are layered on top of one another
    correctly) and uses the Gctx.draw_xyz functions to display them on the
    canvas.  *)

(* TODO: You will need to modify this repaint function in Tasks 2, 3,
   4, and possibly 5 or 6. For example, if the user is performing some
   operation that provides "preview" (see Task 2) the repaint function
   must also show the preview. *)
let repaint (g: gctx) : unit =
  let draw_shape (s: shape) : unit =
    begin match s with
      | Line l -> draw_line (with_params g l.color l.width) l.p1 l.p2
      
      | Ellipse e -> draw_ellipse (with_params g e.color e.width) e.p1 e.rx e.ry

      |Points p -> draw_points (with_params g p.color p.width) p.points

   
    end in
  
  Deque.iterate draw_shape paint.shapes;
  begin match paint.preview with 
    |Some s -> draw_shape (s)
    |_ -> ()
  end
  

(** Create the actual paint_canvas widget and its associated
    notifier_controller . *)
let ((paint_canvas : widget), (paint_canvas_controller : notifier_controller)) =
  canvas (600, 350) repaint


(************************************)
(**  PAINT CANVAS EVENT HANDLER     *)
(************************************)

(** The paint_action function processes all events that occur
    in the canvas region. *)
(* TODO: Tasks 2, 3, 4, 5, and 6 involve changes to paint_action. *)
let paint_action (gc:gctx) (event:event) : unit =
  let p  = event_pos event gc in  (* mouse position *)
  begin match (event_type event) with
    | MouseDown ->
       (* This case occurs when the mouse has been clicked in the
          canvas, but before the button has been released. How we
          process the event depends on the current mode of the paint
          canvas.  *)
      (begin match paint.mode with 
          | LineStartMode ->
            (* The paint_canvas was waiting for the first click of a line,
               so change it to LineEndMode, recording the starting point of
               the line. *)
            paint.mode <- LineEndMode p
          
          | PointMode ->
            paint.preview <- Some (Points {color = paint.color; 
            width = 1; points = [p]})
          
          | EllipseMode -> 
            paint.preview <- Some (Ellipse {color = paint.color; 
            width = paint.line_width; p1 = p; rx = 0;ry = 0})
          | _ -> ()
       end)
    | MouseDrag ->
      (* In this case, the mouse has been clicked, and it's being dragged
         with the button down. Initially there is nothing to do, but you'll
         need to update this part for Task 2, 3, 4 and maybe 6. *)
      (begin match paint.mode with
      |LineEndMode p1 ->
        (*need to draw a line*)
        paint.preview <- Some (Line {color = paint.color; 
        width = paint.line_width; p1 = p1; p2 = p})
      
      | PointMode ->
        let points_list =
          begin match paint.preview with
          | Some (Points ps) -> ps.points
          | _ -> []
          end in 
        
        let new_point: point = p in
        paint.preview <- 
          Some (Points {color = paint.color; 
          width = 1; points = new_point::points_list})
      
      | EllipseMode ->
        
        (*getting the position when user clicked mousedown*)
        let (x1, y1) = 
          begin match paint.preview with 
          | Some Ellipse e -> 
            (*need to find the position when mousedown happened*)
            (*just need to subtract rx and ry from the midpoint*)
            let (midx, midy) = e.p1 in 
            let curr_rx = e.rx in 
            let curr_ry = e.ry in 
            (midx - curr_rx, midy - curr_ry)
          | _ -> (0,0)
          end in
        
        (*getting the current position*)
        let (x2, y2) = p in 

        (*finding the midpoint*)
        let (midx, midy) = ((x1 + x2) / 2,  (y1 + y2) / 2) in 


        (*getting the radius x and radius y*)
        let new_rx = abs(x2 - midx) in 
        let new_ry = abs(y2 - midy) in 
        paint.preview <- Some (Ellipse {color = paint.color; 
        width = paint.line_width; p1 = (midx, midy);rx = new_rx; ry = new_ry})

      |_ -> ()
      end)
    
    | MouseUp ->
      (* In this case there was a mouse button release event. TODO: Tasks 2,
         3, 4, and possibly 6 need to do something different here. *)
      (begin match paint.mode with
      |LineEndMode p1 ->
        (*need to draw a line*)
        Deque.insert_tail (Line {color = paint.color; 
        width = paint.line_width; p1 = p1; p2 = p}) 
        paint.shapes;
        paint.mode <- LineStartMode;
        paint.preview <- None
      
      |PointMode ->
        let points_list =
          begin match paint.preview with 
          |Some (Points ps) -> ps.points
          | _ -> []
          end in 
        Deque.insert_tail (Points {color = paint.color; 
        width = 1; points = points_list})
        paint.shapes;
        paint.preview <- None
      
      |EllipseMode -> 
        let (x1, y1) = 
          begin match paint.preview with 
          |Some (Ellipse e) ->
            let (midx, midy) = e.p1 in 
              let curr_rx = e.rx in 
              let curr_ry = e.ry in 
              (midx - curr_rx, midy - curr_ry)
          |_ -> (0,0)
          end in 
        let (x2, y2) = p in 
        let midx, midy = ((x1 + x2) / 2, (y1 + y2) / 2) in
        let new_rx = abs(x2 - midx) in 
        let new_ry = abs(y2 - midy) in 
        Deque.insert_tail (Ellipse {color = paint.color; 
        width = paint.line_width; p1 = (midx, midy); rx = new_rx; ry = new_ry}) 
        paint.shapes;
        paint.preview <- None
      |_ -> ()
      end)
    
    | _ -> ()
    (* This catches the MouseMove event (where the user moved the mouse over
       the canvas without pushing any buttons) and the KeyPress event (where
       the user typed a key when the mouse was over the canvas). *)
  end

(** Add the paint_action function as a listener to the paint_canvas *)
;; paint_canvas_controller.add_event_listener paint_action


(**************************************)
(** TOOLBARS AND PAINT PROGRAM LAYOUT *)
(**************************************)

(** This part of the program creates the other widgets for the paint
    program -- the buttons, color selectors, etc., and lays them out
    in the top - level window. *)
(* TODO: Tasks 1, 4, 5, and 6 involve adding new buttons or changing
   the layout of the Paint GUI. Initially the layout is ugly because
   we use only the hpair widget demonstrated in Lecture. Task 1 asks
   you to make improvements to make the layout more appealing. You may
   choose to arrange the buttons and other GUI elements of the paint
   program however you like, so long as it is easily apparent how to
   use the interface; the sample screenshot in the homework
   description shows one possible design. Also, feel free to improve
   the visual components of the GUI; for example, our solution puts
   borders around the buttons and uses a custom "color button" that
   changes its appearance based on whether or not the color is
   currently selected. *)

(** A spacer widget *)
let spacer : widget = space (10,10)


(** Create the Undo button *)
let (w_undo, lc_undo, nc_undo) = button "Undo"


(*creating the checkbox*)
let w_checkbox, check_control  = checkbox false "Thickness"

let update_line_thickness(box_checked: bool) =
  if box_checked then paint.line_width <- 10
  else paint.line_width <- 1

;; check_control.add_change_listener (update_line_thickness)

let mode_list = [(LineStartMode, "Line"); (PointMode, "Point"); 
 (EllipseMode, "Ellipse")]

let mode_boxes, mode_controller = radio_group mode_list LineStartMode 

let update_mode (selection: 'a) = 
  paint.mode <- selection

;;mode_controller.add_change_listener (update_mode)

  
(** This function runs when the Undo button is clicked.
    It simply removes the last shape from the shapes deque. *)
(* TODO: You need to modify this in Task 3 and 4, and potentially in
   Task 2 (depending on your implementation). *)

let undo () : unit =
  if Deque.is_empty paint.shapes then () else
    ignore (Deque.remove_tail paint.shapes)

;; nc_undo.add_event_listener (mouseclick_listener undo)


(** The mode toolbar, initially containing just the Undo button.
    TODO: you will need to modify this widget to add more buttons
    to the toolbar in Task 1, 3, 4, 5, and possibly 6. *)
(*  
let mode_toolbar : widget = Widget.hlist [w_undo; spacer; w_line; spacer; 
w_point; spacer; w_ellipse; spacer; w_checkbox]*)

let mode_toolbar: widget = Widget.hlist [w_undo; spacer; 
Widget.hlist mode_boxes; w_checkbox]



(* The color selection toolbar. *)
(* This toolbar contains an indicator for the currently selected color
   and some buttons for changing it. Both the indicator and the buttons
   are small square widgets built from this higher-order function. *)
(** Create a widget that displays itself as colored square with the given
    width and color specified by the [get_color] function. *)
let colored_square (width:int) (get_color:unit -> color)
  : widget * notifier_controller =
  let repaint_square (gc:gctx) =
    let c = get_color () in
    fill_rect (with_color gc c) (0, 0) (width-1, width-1) in
  canvas (width,width) repaint_square

(** The color_indicator repaints itself with the currently selected
    color of the paint application. *)
let color_indicator =
  let indicator,_ = colored_square 24 (fun () -> paint.color) in
  let lab, _ = label "Current Color" in
  border (hpair lab indicator)

(** color_buttons repaint themselves with whatever color they were created
    with; they are also installed with a mouseclick listener
    that changes the selected color of the paint app to their color. *)
let color_button (c: color) : widget =
  let w,nc = colored_square 10 (fun () -> c) in
  nc.add_event_listener (mouseclick_listener (fun () ->
      paint.color <- c ));
  w

(** The color selection toolbar. Contains the color indicator and
    buttons for several different colors. *)
(* TODO: Task 1 - This code contains a great deal of boilerplate.  You
     should come up with a better, more elegant, more concise solution... *)
let color_toolbar : widget =
  Widget.hlist [color_indicator; spacer; color_button black; spacer;
  color_button white; spacer; color_button red; spacer; color_button green; 
  spacer; color_button blue; spacer; color_button yellow; spacer;
  color_button cyan; spacer; color_button magenta]

(** The top-level paint program widget: a combination of the
    mode_toolbar, the color_toolbar and the paint_canvas widgets. *)
(* TODO: Task 1 (and others) involve modifing this layout to add new
   buttons and make the layout more aesthetically appealing. *)
let paint_widget =
   
   Widget.vlist [paint_canvas; spacer; mode_toolbar; spacer;
   color_toolbar]


(**************************************)
(**      Start the application        *)
(**************************************)

(** Run the event loop to process user events. *)
;; Eventloop.run paint_widget
