<?php
declare(strict_types = 1);

//========================================================================================================================================
/** Функция, выводящая слова с разными окончаниями в зависимости от числа. Например '1 яблоко', '25 яблок', '432 яблока'.
 * 
 * @param integer $n - число к которому писать величины
 * @param array[3] $titles - массив величин. 
 *      0-й элемент - вижу одно|один (день).
 *      1-й элемент - вижу два (дня).
 *      2-й элемент - вижу пять (дней).

 *     echo number(631, array('день', 'дня', 'дней'));
 *     выведет 'день'.
 * @return type
 */
function number($n, $titles) {
  $cases = array(2, 0, 1, 1, 1, 2);
  return $titles[($n % 100 > 4 && $n % 100 < 20) ? 2 : $cases[min($n % 10, 5)]];
}
