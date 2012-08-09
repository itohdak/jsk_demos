;; open fridge and pick a can (and close the door)

(load "package://jsk_2011_07_pr2_semantic/euslisp/actions.l")
(load "package://jsk_maps/src/eng2-scene.l")
(load "package://pr2eus/pr2-interface.l")
(load "package://pr2eus_openrave/pr2eus-openrave.l")

(ros::roseus "demo_main")

(defun init-for-perception ()
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
  (unless (boundp '*tfb*)
    (setq *tfb* (instance ros::transform-broadcaster :init)))
  (if (and x::*display* (/= x::*display* 0)) (make-irtviewer))
  (setq *obj* (make-sphere 100)) ;; dummy object
  (ros::spin-once)
  )

(defun init-for-robot ()
  (unless (boundp '*pr2*) (pr2))
  (unless (boundp '*ri*) (setq *ri* (instance pr2-interface :init)))
  (send *ri* :spin-once)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  )

(defun init ()
  (init-for-perception)
  (init-for-robot)
  ;;(send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  ;;(objects (list *pr2*))
  )

(defun grasp-can-single (obj)
  (let (via1 via2 tar orig-av)
    (send *ri* :stop-grasp :rarm)
    (send *tfb* :send-transform
	  obj "/base_footprint" "/objecta_pose_frame")
    (setq orig-av (send *ri* :state :potentio-vector))

    (setq tar (send obj :copy-worldcoords))
    (send tar :orient 0 :z :world)

    (setq via1 (send tar :copy-worldcoords))
    (send via1 :translate (float-vector -100 0 0) :world)

    (setq via2 (send tar :copy-worldcoords))
    (send via2 :translate (float-vector -50 0 0) :world)

    (setq via3 (send tar :copy-worldcoords))
    (send via3 :translate (float-vector 30 0 0) :world)

    ;; publish tf
    (send *tfb* :send-transform
	  via1 "/base_footprint" "/objecta_pose_frame_via1")
    (send *tfb* :send-transform
	  via2 "/base_footprint" "/objecta_pose_frame_via2")
    (send *tfb* :send-transform
	  via3 "/base_footprint" "/objecta_pose_frame_via3")
    ;;
    (send *pr2* :rarm :inverse-kinematics via1 :rotation-axis t :use-torso t)
    (send *tfb* :send-transform
	  (send *pr2* :rarm :end-coords)  "/base_footprint" "/objecta_pose_end_coords")

    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    ;;
    (send *pr2* :rarm :inverse-kinematics via3 :rotation-axis t :use-torso t)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    (send *ri* :start-grasp :rarm)

    ;;
    (send *pr2* :rarm :inverse-kinematics via1 :rotation-axis t :use-torso t)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    ;;
    (send *ri* :angle-vector orig-av)
    (send *ri* :wait-interpolation)
    )
  )

(defun goto-front-of-fridge ()
  (let ((co (send *scene* :spot "/eng2/7f/room73B2-fridge-front")))
    (send co :translate (float-vector 0 0 0) :world) ;; for opening door
    (send *ri* :move-to co)
    (send *ri* :go-pos 0 -0.04 0) ;; ???
  ;;
    (send *pr2* :head :angle-vector (float-vector 0 0))
    (send *pr2* :torso :angle-vector (float-vector 50))
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    ;;(send *pr2* :move-to (send *ri* :state :worldcoords) :world)
    t
    ))

(defun open-fridge-door ()
  (let (ret
	(idealcds (make-coords :pos (float-vector 733.757 135.013 1092.946)
			       :rpy (float-vector 0.002 0.059 -0.019)))
	(diffcds (make-coords :pos (float-vector 10000 10000 10000))))
    (dotimes (i 10 nil)
      ;; finding handle position
      (check :type "fridge") ;; need detection fail check
      ;; opening door
      (warn ";; print check frig~%")
      (dump-structure *standard-output*
                      (list (send *pr2* :copy-worldcoords)
                            (send *obj* :copy-worldcoords)))
      (setq diffcds (send (send *obj* :copy-worldcoords)
			  :transform (send idealcds :inverse-transformation)))
      (send *ri* :go-pos-unsafe
	    (/ (elt (send diffcds :worldpos) 0) 1000.0)
	    (/ (elt (send diffcds :worldpos) 1) 1000.0)
	    (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0)))
      ;;(send *obj* :move-to idealcds :world)
      (check :type "fridge")
      (ros::spin-once)
      (send *ri* :spin-once)
      (when (setq ret (open-fridge :rarm *obj* (/ pi 2)))
        (return))
      (speak-jp "こまった") (speak-jp ".") (unix::sleep 3)
      )
    (when (not ret)
      (format t "(demo2 :type \"~a\")" type)
      (return-from open-fridge-door nil))

    ;; free door handle
    (ros::spin-once)
    (send *ri* :spin-once)
    (send *ri* :stop-grasp :rarm)
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (setq rend (send *pr2* :rarm :end-coords :copy-worldcoords))
    (send rend :translate (float-vector -100 -50 0) *pr2*)
    (send *pr2* :rarm :inverse-kinematics rend)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)

    ;; ?? open door ()
    (send *ri* :angle-vector-sequence
	  (list (float-vector 50 5 74 100 -90 -70 -6 20 -70 50 -59 -43 118 0 0 -2 31)
		(float-vector 50 5 74 100 -90 -70 -6 20 -0 60 -20 -90 118 -90 0 -2 31)
		(float-vector 50 5 74 100 -90 -70 -6 20 -7 45 -34 -110 12 -38 74 -2 31)
		(float-vector 50 5 74 100 -90 -70 -6 20 -45 26 -31 -62 22 -76 121 -2 31)
		(float-vector 150 5 74 100 -90 -70 -6 20 -7 45 -34 -110 12 -38 74 -2 31))
	  (list 1500 1000 1000 3000 3000))
    (send *ri* :wait-interpolation)

    ;; (send *pr2* :angle-vector (float-vector 200 5.00529 74.2038 105.001 -90.0035 -70.0071 -5.73378 19.9988 9.96029 39.7801 -45.0972 -121.542 94.4262 -111.922 63.0666 -0.0316 21.024))
    (send *pr2* :angle-vector (float-vector 199.971 5.30455 72.1244 105.231 -88.5188 -69.9972 -5.72958 19.9717 24.6812 36.1934 10.6903 -121.497 159.113 -79.5111 -2.92658 -1.35562 26.862))
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    t
    ))

(defun grasp-can ()
  ;; move-to spot for grasping
  (ros::spin-once)
  (send *ri* :spin-once)
  (ros::ros-info "GO POS UNSAFE")
  (send *ri* :go-pos-unsafe 0 0 (rad2deg 0.40))
  ;;(send *ri* :go-pos-unsafe 0.15 -0.30 0)
  (send *ri* :go-pos-unsafe 0.18 -0.31 0)
  (send *ri* :wait-interpolation)

  (ros::spin-once)
  (send *ri* :spin-once)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (let (isgrasp)
    (dotimes (trial 10)
      ;; detect cans which was indicated by ( type )
      (when (not (check :type *type*))
	(check :type *type* :tf-force t :timeout 30))
      (warn ";; print check cans~%")
      (dump-structure *standard-output*
		      (list (send *pr2* :copy-worldcoords)
			    (send *obj* :copy-worldcoords)))
      (unless (boundp '*tfb*)
	(setq *tfb* (instance ros::transform-broadcaster :init)))
      (send *tfb* :send-transform
	    *obj* "/base_footprint" "/object_pose_frame")
      (grasp-can-single *obj*)
      (setq isgrasp (< 10 (send *ri* :start-grasp :rarm)))
      (when isgrasp
	(return-from grasp-can t))
      ))
  nil)

(defun close-fridge ()
  ;; close the door of fridge
  (send *ri* :go-pos-unsafe -0.3 0.05 -20)
  (unix::sleep 1)
  (send *ri* :angle-vector-sequence
	(list (float-vector 250 5 74 100 -90 -70 -6 20 -13 50 -59 -43 118 -90 62 -2 31)
	      (float-vector 200 5 74 100 -90 -70 -6 20 -50 36 -29 -43 118 -90 62 -2 31)
	      (float-vector 150 5 74 100 -90 -70 -6 20 -63 10 -39 -33 -49 -32 89 -2 32)
	      (float-vector 100 5 74 100 -90 -70 -6 20 -61 6 -74 -64 -35 -6 102 -2 33)
	      (float-vector 50 5 74 100 -90 -70 -6 20 3 -2 -64 -80 -24 -55 10 -2 33))
	(list 2000 1000 3000 2000 2000))
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (pr2-tuckarm-pose :rarm)
  t
  )

(defun goto-initial-position (&key (return-to-initial-position t))
  (send *ri* :go-pos-unsafe 0 0 -90)
  (when return-to-initial-position
    (send *ri* :move-to *opose*))

  (speak-jp (format nil "~a を どうぞ" (send *obj* :name)))
  (hand-over :rarm :wait-shock t)
  t
  )

(defun demo (&key (type "georgia"))
  ;;(init)
  (setq *type* type)
  (pr2-tuckarm-pose :rarm)
  (setq *opose* (send *ri* :state :worldcoords))

  (unless (goto-front-of-fridge)
    (return-from demo))

  (unless (open-fridge-door)
    (return-from demo))

  (unless (grasp-can)
    (return-from demo))

  (unless (close-fridge)
    (return-from demo))

  (unless (goto-initial-position)
    (return-from demo))
  )

(defun wait-query ()
  (setq *type* nil)
  (ros::subscribe "/query" std_msgs::String
		  #'(lambda(m) (setq *type* (send m :data))))
  #|(ros::subscribe "/query" std_msgs::String
		  #'(lambda(m)(setq *type* (send m :data))))|#
  (do-until-key
   (ros::spin-once)
   (send *ri* :spin-once)
   (when *type*
     (ros::unsubscribe "/query")
     (demo *type*)
     (return-from wait-query t))
   (ros::sleep))
  )

(warn ";; (init)~%")
(warn ";; (demo)~%")
(warn ";; (demo :type \"georgia\")~%")
(warn ";; (demo :type \"iemon\")~%")
(warn ";; (demo :type \"wonda\")~%")
(warn ";; ~%")
(warn ";; (check :type \"fridge\")~%")

;; (progn (check :type "wonda")(grasp-can *obj*))