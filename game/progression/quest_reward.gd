class_name LunexQuestReward
extends Resource

@export var quest_id := "training"
@export var prerequisite_id := ""
@export var target_id := "training"
@export var objective := "Победите тренировочную цель"
@export var slot_name := "Кольцо"
@export var quest_title := "Тренировочный бой"
@export var item_id := "training_ring"
@export var item_name := "Кольцо ученика"
@export_range(1, 100000) var experience := 25
