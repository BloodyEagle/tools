<?php
declare(strict_types = 1);

/** Функция проверки корректности СНИЛС
	 * @param string $snils - номер СНИЛС в формате ХХХ-ХХХ-ХХХ ХХ
	 * @param string $error_message - сюда пишутся сообщения об ошибках
	 * @param mixed $error_code - код ошибки
	 * @return boolean - true если СНИЛС соответствует, false если ошибочный
	 **/
    function validateSnils($snils, &$error_message = null, $error_code = null) {
	$result = false;
	$snils = (string) $snils;
	if (!$snils) {
		$error_code = 1;
		$error_message = 'СНИЛС пуст';
	} elseif (!preg_match('/^\d{3}-\d{3}-\d{3}\s\d{2}$/', $snils)) {
		$error_code = 2;
		$error_message = 'СНИЛС может состоять только из цифр';
	} elseif (strlen($snils) !== 14) {
		$error_code = 3;
		$error_message = 'СНИЛС может состоять только из 11 цифр';
	} else {
		$sum = 0;
                
                $sum += (int) $snils[0]*9;
                $sum += (int) $snils[1]*8;
                $sum += (int) $snils[2]*7;
                $sum += (int) $snils[4]*6;
                $sum += (int) $snils[5]*5;
                $sum += (int) $snils[6]*4;
                $sum += (int) $snils[8]*3;
                $sum += (int) $snils[9]*2;
                $sum += (int) $snils[10]*1;

                $check_digit = 0;
		if ($sum < 100) {
			$check_digit = $sum;
		} elseif ($sum > 101) {
			$check_digit = $sum % 101;
			if ($check_digit === 100) {
				$check_digit = 0;
			}
		}
		if ($check_digit === (int) substr($snils, -2)) {
			$result = true;
		} else {
			$error_code = 4;
			$error_message = 'Неправильное контрольное число СНИЛС';
		}
	}
        return $result;
}
