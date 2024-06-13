<?php 

/**
* Функция кодирования интернационализированных доменных имен типа http://сайт.рф/item в нормальный вид
* @param string $url - интернационализированный адрес сайта
* @return string - перекодированный адрес
*
* например echo encodeLocalisedUrl('http://сайт.рф/item') вернет  'http://xn--80aswg.xn--p1ai/item'
*/

function encodeLocalisedUrl(string $url)
{
	$data = parse_url($url);
 
	$result = '';
	if (!empty($data['scheme']))   $result .= $data['scheme'] . ':';
	if (!empty($data['host']))     $result .= '//';
	if (!empty($data['user']))     $result .= $data['user'];
	if (!empty($data['pass']))     $result .= ':' . $data['pass'];
	if (!empty($data['user']))     $result .= '@';
	if (!empty($data['host']))     $result .= idn_to_ascii($data['host']);
	if (!empty($data['port']))     $result .= ':' . $data['port'];
	if (!empty($data['path']))     $result .= $data['path'];
	if (!empty($data['query']))    $result .= '?' . $data['query'];
	if (!empty($data['fragment'])) $result .= '#' . $data['fragment'];
 
	return $result;
}

/**
* Функция декодирования интернационализированных доменных имен типа http://xn--80aswg.xn--p1ai в локализированный вид
* @param string $url - адрес сайта
* @return string - раскодированный адрес
*
* например echo decodeLocalisedUrl('http://xn--80aswg.xn--p1ai/item') вернет  'http://сайт.рф/item'
*/

function decodeLocalisedUrl(string $url)
{
	$data = parse_url($url);
 
	$result = '';
	if (!empty($data['scheme']))   $result .= $data['scheme'] . ':';
	if (!empty($data['host']))     $result .= '//';
	if (!empty($data['user']))     $result .= $data['user'];
	if (!empty($data['pass']))     $result .= ':' . $data['pass'];
	if (!empty($data['user']))     $result .= '@';
	if (!empty($data['host']))     $result .= idn_to_utf8($data['host']);
	if (!empty($data['port']))     $result .= ':' . $data['port'];
	if (!empty($data['path']))     $result .= $data['path'];
	if (!empty($data['query']))    $result .= '?' . $data['query'];
	if (!empty($data['fragment'])) $result .= '#' . $data['fragment'];
 
	return $result;
} 
