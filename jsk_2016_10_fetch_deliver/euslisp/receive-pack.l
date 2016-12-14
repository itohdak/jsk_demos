#!/usr/bin/env roseus

;;(load "package://fetcheus/fetch-interface.l")
;;(fetch-init t)

(ros::load-ros-manifest "roseus")

(ros::roseus "inkan")
;;(ros::advertise "go_to_room" std_msgs::string 1)
(ros::advertise "pick_up" std_msgs::string 1) ;;要相談

(defun inkan nil
  ;;受け取った荷物を置く
  #|
  (send *ri* :angle-vector
	(send *fetch* :inverse-kinematics
	      (make-coords :pos #f(400 400 1000))) 5000)
  (send *ri* :wait-interpolation)
  ;;(unix:sleep 7)
  (send *ri* :stop-grasp :effort 30)
  |#
  (send *ri* :stop-grasp :effort 30)

  ;;印鑑を握る
  (send *ri* :angle-vector #f(13.4507 -68.0538 6.02191 -104.249 87.3323 2.90398 104.686 76.432 8.0667 1.39715))
  (send *ri* :wait-interpolation)

  (send *ri* :angle-vector #f(13.4507 -67.0325 6.62849 -103.939 97.1639 3.2024 95.9892 76.716 8.0667 1.39715))
  (send *ri* :wait-interpolation)

  ;;(send *ri* :angle-vector
  ;;	(send *fetch* :inverse-kinematics
  ;;	      (make-coords :pos #f(450 -400 1100))) 5000)
  ;;(send *ri* :wait-interpolation)
  
  ;;(send *ri* :angle-vector
  ;;	(send *fetch* :inverse-kinematics
  ;;	      (make-coords :pos #f(450 -400 1000))) 2000)
  ;;(send *ri* :wait-interpolation)

  ;;印鑑を持ち上げる
  (send *ri* :start-grasp :effort 50)
  (send *ri* :angle-vector #f(13.4507 -68.1333 -0.222329 -109.902 94.7688 -4.13147 95.2902 71.946 8.0667 1.39715))
  (send *ri* :wait-interpolation)
  
  ;;印鑑を押す
  (send *ri* :angle-vector
	(send *fetch* :inverse-kinematics
	      (make-coords :pos #f(800 0 1000))) 5000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :angle-vector
	(send *fetch* :inverse-kinematics
	      (make-coords :pos #f(800 0 900))) 500)
  (send *ri* :wait-interpolation)
  
  ;;(send *ri* :speak "please set the paper" :wait t)
  (send *ri* :angle-vector
	(send *fetch* :inverse-kinematics
	      (make-coords :pos #f(800 0 1000))) 500)
  (send *ri* :wait-interpolation)
  ;;(send *ri* :speak "thank you" :wait t)
  

  ;;印鑑を元に戻す
  (send *ri* :angle-vector #f(13.4507 -68.1333 -0.222329 -109.902 94.7688 -4.13147 95.2902 71.946 8.0667 1.39715))
  (send *ri* :wait-interpolation)

  (send *ri* :angle-vector #f(13.4507 -67.0325 6.62849 -103.939 97.1639 3.2024 95.9892 76.716 8.0667 1.39715))
  (send *ri* :wait-interpolation)

  ;;(send *ri* :angle-vector
  ;;	(send *fetch* :inverse-kinematics
  ;;	      (make-coords :pos #f(450 -400 1000))) 5000)
  ;;(send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :effort 30)

  (send *ri* :angle-vector #f(13.4507 -68.0538 6.02191 -104.249 87.3323 2.90398 104.686 76.432 8.0667 1.39715))
  (send *ri* :wait-interpolation)

  ;;(send *ri* :angle-vector
  ;;	(send *fetch* :inverse-kinematics
  ;;	      (make-coords :pos #f(450 -400 1100))) 5000)
  ;;(send *ri* :wait-interpolation)
  ;;(send *ri* :angle-vector #f(13.4507 -67.0325 6.62849 -103.939 97.1639 3.2024 95.9892 -104.716 8.0667 1.39715))
  ;;(send *ri* :wait-interpolation)

  ;;腕をしまう
  (send *ri* :angle-vector
	(send *fetch* :reset-pose) 3000)
  (send *ri* :wait-interpolation)
  
  ;;印鑑を押し終わったら、トピック"go_to_room"で行き先の部屋番号を伝える
  ;;(部屋番号の決定方法はまだ考慮できていません(以下は73A2の例))
  ;;(setq msg (instance std_msgs::string :init))
  ;;(send msg :data (format nil "home-point"))
  ;;(ros::ros-info "msg [~A]" (send msg :data))
  ;;(ros::publish "go_to_room" msg))

  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "go"))
  (ros::ros-info "inkan finished")
  (ros::publish "pick_up" msg))


;;トピック"delivery"でメッセージを受信した時のコールバック関数
;;メッセージの内容が"ok"ならば、印鑑を押すフェーズへ
(defun task2-cb
  (msg)
  (let (delivery)
    (setq delivery (send msg :data))
    (print delivery)
    (if (string= delivery "ok")
	(inkan))))

;;(do-until-key
;; (ros::subscribe "received" std_msgs::string #'task2-cb)
;; (ros::spin())
;;)

(ros::subscribe "delivery" std_msgs::string #'task2-cb)
(ros::spin)
