<?php

/**
* Функция возвращает информацию о городе по IP адресу
* @param string $user_ip - IP адрес
* @return array - массив данных с ключами 'city', 'region' и 'country'. Содержащие названия города, региона и страны соответственно
* 
* используется sypex geo - https://sypexgeo.net/
*/

function getGeoCityInfo(string $user_ip){
	$user_ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
	if (strlen($user_ip) > 15)
		return false;
	
	include_once __DIR__ . '/SxGeo/SxGeo.php';
	$SxGeo = new SxGeo(__DIR__ . '/SxGeo/SxGeoCity.dat', SXGEO_BATCH | SXGEO_MEMORY); 			
	$res = $SxGeo->getCityFull($user_ip); 		
 
	if (!empty($res['city']['name_ru'])) {
		return $res;
	} else {
		return false;
	}
}